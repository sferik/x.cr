require "./authenticator.cr"
require "openssl"
require "openssl/hmac"
require "digest/sha1"
require "base64"
require "uri"
require "json"

module X
  class OAuthAuthenticator < Authenticator
    OAUTH_VERSION             = "1.0"
    OAUTH_SIGNATURE_METHOD    = "HMAC-SHA1"
    OAUTH_SIGNATURE_ALGORITHM = OpenSSL::Algorithm::SHA1

    property api_key : String
    property api_key_secret : String
    property access_token : String
    property access_token_secret : String

    def initialize(@api_key : String, @api_key_secret : String, @access_token : String, @access_token_secret : String)
    end

    def header(request : HTTP::Request)
      method = request.method
      url = uri_without_query(request.resource)
      query_params = parse_query_params(URI.parse(request.resource).query.to_s)
      {AUTHENTICATION_HEADER => build_oauth_header(method, url, query_params)}
    end

    private def parse_query_params(query_string : String)
      URI::Params.parse(query_string).to_h
    end

    private def uri_without_query(uri_str : String)
      uri = URI.parse(uri_str)
      "#{uri.scheme}://#{uri.host}#{uri.path}"
    end

    private def build_oauth_header(method : String, url : String, query_params : Hash(String, String))
      oauth_params = default_oauth_params
      all_params = query_params.merge(oauth_params)
      oauth_params["oauth_signature"] = generate_signature(method, url, all_params)
      format_oauth_header(oauth_params)
    end

    private def default_oauth_params
      {
        "oauth_consumer_key"     => api_key,
        "oauth_nonce"            => Random::Secure.hex(16),
        "oauth_signature_method" => OAUTH_SIGNATURE_METHOD,
        "oauth_timestamp"        => Time.utc.to_unix.to_s,
        "oauth_token"            => access_token,
        "oauth_version"          => OAUTH_VERSION,
      }
    end

    private def generate_signature(method : String, url : String, params : Hash(String, String))
      base_string = signature_base_string(method, url, params)
      hmac_signature(base_string)
    end

    private def hmac_signature(base_string : String)
      digest = OpenSSL::HMAC.digest(OAUTH_SIGNATURE_ALGORITHM, signing_key, base_string)
      Base64.strict_encode(digest)
    end

    private def signature_base_string(method : String, url : String, params : Hash(String, String))
      encoded = params.to_a.sort.map { |k, v|
        key = URI.encode_www_form(k, space_to_plus: false)
        value = URI.encode_www_form(v, space_to_plus: false)
        "#{key}=#{value}"
      }.join("&")
      meth = URI.encode_www_form(url, space_to_plus: false)
      encoded = URI.encode_www_form(encoded, space_to_plus: false)
      "#{method}&#{meth}&#{encoded.gsub("+", "%20")}"
    end

    private def signing_key
      "#{api_key_secret}&#{access_token_secret}"
    end

    private def format_oauth_header(params : Hash(String, String))
      "OAuth " + params.to_a.sort.map do |k, v|
        value = URI.encode_www_form(v, space_to_plus: false)
        "#{k}=\"#{value}\""
      end.join(", ")
    end
  end
end
