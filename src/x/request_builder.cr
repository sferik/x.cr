require "http/request"
require "./authenticator.cr"
require "./version.cr"
require "uri"

module X
  class RequestBuilder
    DEFAULT_HEADERS = {
      "Content-Type" => "application/json; charset=utf-8",
      "User-Agent"   => "X-Client/#{VERSION} Crystal/#{Crystal::VERSION}",
    }

    HTTP_METHODS = {
      get:    "GET",
      post:   "POST",
      put:    "PUT",
      delete: "DELETE",
    }

    def build(http_method : Symbol, uri : URI, body : String? = nil, headers : Hash(String, String) = Hash(String, String).new, authenticator : Authenticator = Authenticator.new)
      request = create_request(http_method, uri, body)
      add_headers(request, headers)
      add_authentication(request, authenticator)
      request
    end

    private def create_request(http_method : Symbol, uri : URI, body : String?)
      method = HTTP_METHODS[http_method]?
      raise ArgumentError.new("Unsupported HTTP method: #{http_method}") if method.nil?
      resource = escape_query_params(uri).to_s
      HTTP::Request.new(method, resource, body: body)
    end

    private def add_authentication(request : HTTP::Request, authenticator : Authenticator)
      authenticator.header(request).each do |k, v|
        request.headers[k] = v
      end
    end

    private def add_headers(request : HTTP::Request, headers : Hash(String, String))
      DEFAULT_HEADERS.merge(headers).each do |k, v|
        request.headers[k] = v
      end
    end

    private def escape_query_params(uri : URI)
      u = uri.dup
      if q = u.query
        u.query = URI.encode_www_form(URI.decode_www_form(q)).gsub("%2C", ",")
      end
      u
    end
  end
end
