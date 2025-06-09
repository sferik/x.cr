require "http/request"
require "http/client"
require "./authenticator.cr"
require "./connection.cr"
require "./errors"
require "./request_builder.cr"
require "uri"

module X
  class RedirectHandler
    DEFAULT_MAX_REDIRECTS = 10

    property max_redirects : Int32
    property connection : Connection
    property request_builder : RequestBuilder

    def initialize(@connection = Connection.new, @request_builder = RequestBuilder.new, @max_redirects = DEFAULT_MAX_REDIRECTS)
    end

    def handle(response : HTTP::Client::Response, request : HTTP::Request, base_url : String, authenticator : Authenticator = Authenticator.new, redirect_count : Int32 = 0)
      if response.status_code.in?(300..399)
        raise TooManyRedirects.new("Too many redirects") if redirect_count > max_redirects
        new_uri = build_new_uri(response, base_url)
        new_request = build_request(request, new_uri, response.status_code, authenticator)
        new_response = connection.perform(new_request)
        handle(new_response, new_request, base_url, authenticator, redirect_count + 1)
      else
        response
      end
    end

    private def build_new_uri(response : HTTP::Client::Response, base_url : String)
      location = response.headers["Location"]
      URI.parse(base_url).resolve(location)
    end

    private def build_request(request : HTTP::Request, uri : URI, response_code : Int32, authenticator : Authenticator)
      http_method = :get
      body = nil
      if {307, 308}.includes?(response_code)
        method_str = request.method.downcase
        http_method = case method_str
                      when "post"   then :post
                      when "put"    then :put
                      when "delete" then :delete
                      else               :get
                      end
        if io = request.body
          body = io.gets_to_end
        else
          body = nil
        end
      end
      request_builder.build(http_method, uri, body, authenticator: authenticator)
    end
  end
end
