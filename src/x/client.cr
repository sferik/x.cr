require "./bearer_token_authenticator.cr"
require "./connection.cr"
require "./oauth_authenticator.cr"
require "./redirect_handler.cr"
require "./request_builder.cr"
require "./response_parser.cr"

module X
  class Client
    DEFAULT_BASE_URL = "https://api.twitter.com/2/"

    property base_url : String
    property api_key : String?
    property api_key_secret : String?
    property access_token : String?
    property access_token_secret : String?
    property bearer_token : String?
    property max_redirects : Int32
    property default_array_class
    property default_object_class
    @authenticator : Authenticator = Authenticator.new

    def initialize(@api_key : String? = nil, @api_key_secret : String? = nil, @access_token : String? = nil, @access_token_secret : String? = nil,
                   @bearer_token : String? = nil, @base_url = DEFAULT_BASE_URL,
                   open_timeout = Connection::DEFAULT_OPEN_TIMEOUT,
                   read_timeout = Connection::DEFAULT_READ_TIMEOUT,
                   write_timeout = Connection::DEFAULT_WRITE_TIMEOUT,
                   debug_output = Connection::DEFAULT_DEBUG_OUTPUT,
                   proxy_url = nil,
                   default_array_class = Array,
                   default_object_class = Hash,
                   @max_redirects = RedirectHandler::DEFAULT_MAX_REDIRECTS)
      @default_array_class = default_array_class
      @default_object_class = default_object_class
      initialize_authenticator
      @connection = Connection.new(open_timeout, read_timeout, write_timeout, debug_output, proxy_url)
      @request_builder = RequestBuilder.new
      @redirect_handler = RedirectHandler.new(@connection, @request_builder, max_redirects)
      @response_parser = ResponseParser.new
    end

    def get(endpoint : String, headers : Hash(String, String) = Hash(String, String).new, array_class = default_array_class, object_class = default_object_class)
      execute_request(:get, endpoint, headers: headers, array_class: array_class, object_class: object_class)
    end

    def post(endpoint : String, body : String? = nil, headers : Hash(String, String) = Hash(String, String).new, array_class = default_array_class, object_class = default_object_class)
      execute_request(:post, endpoint, body: body, headers: headers, array_class: array_class, object_class: object_class)
    end

    def put(endpoint : String, body : String? = nil, headers : Hash(String, String) = Hash(String, String).new, array_class = default_array_class, object_class = default_object_class)
      execute_request(:put, endpoint, body: body, headers: headers, array_class: array_class, object_class: object_class)
    end

    def delete(endpoint : String, headers : Hash(String, String) = Hash(String, String).new, array_class = default_array_class, object_class = default_object_class)
      execute_request(:delete, endpoint, headers: headers, array_class: array_class, object_class: object_class)
    end

    def api_key=(val : String?)
      @api_key = val
      initialize_authenticator
    end

    def api_key_secret=(val : String?)
      @api_key_secret = val
      initialize_authenticator
    end

    def access_token=(val : String?)
      @access_token = val
      initialize_authenticator
    end

    def access_token_secret=(val : String?)
      @access_token_secret = val
      initialize_authenticator
    end

    def bearer_token=(val : String?)
      @bearer_token = val
      initialize_authenticator
    end

    private def initialize_authenticator
      @authenticator = if api_key && api_key_secret && access_token && access_token_secret
                         OAuthAuthenticator.new(api_key.not_nil!, api_key_secret.not_nil!, access_token.not_nil!, access_token_secret.not_nil!)
                       elsif bearer_token
                         BearerTokenAuthenticator.new(bearer_token.not_nil!)
                       else
                         Authenticator.new
                       end
    end

    private def execute_request(http_method : Symbol, endpoint : String, body : String? = nil, headers : Hash(String, String) = Hash(String, String).new, array_class = default_array_class, object_class = default_object_class)
      uri = URI.parse(base_url).resolve(endpoint)
      request = @request_builder.build(http_method, uri, body, headers, @authenticator)
      response = @connection.perform(request)
      response = @redirect_handler.handle(response, request, base_url, @authenticator)
      @response_parser.parse(response, array_class, object_class)
    end
  end
end
