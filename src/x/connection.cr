require "http/request"
require "http/client"
require "./errors"
require "uri"

module X
  class Connection
    DEFAULT_HOST          = "api.twitter.com"
    DEFAULT_PORT          = 443
    DEFAULT_OPEN_TIMEOUT  = 60.seconds
    DEFAULT_READ_TIMEOUT  = 60.seconds
    DEFAULT_WRITE_TIMEOUT = 60.seconds
    DEFAULT_DEBUG_OUTPUT  = File.open(File::NULL, "w")

    property open_timeout : Time::Span
    property read_timeout : Time::Span
    property write_timeout : Time::Span
    property debug_output : IO
    property proxy_url : String?
    property proxy_uri : URI?

    def initialize(@open_timeout = DEFAULT_OPEN_TIMEOUT, @read_timeout = DEFAULT_READ_TIMEOUT,
                   @write_timeout = DEFAULT_WRITE_TIMEOUT, @debug_output = DEFAULT_DEBUG_OUTPUT,
                   @proxy_url : String? = nil)
      self.proxy_url = proxy_url if proxy_url
    end

    def proxy_url=(url : String)
      @proxy_url = url
      uri = URI.parse(url)
      raise ArgumentError.new("Invalid proxy URL: #{uri}") unless uri.scheme =~ /^https?/i
      @proxy_uri = uri
    end

    def perform(request : HTTP::Request) : HTTP::Client::Response
      host = URI.parse(request.resource).host || DEFAULT_HOST
      port = URI.parse(request.resource).port || DEFAULT_PORT
      client = build_http_client(host, port)
      begin
        client.exec(request)
      rescue ex
        raise NetworkError.new("Network error: #{ex}")
      ensure
        client.close
      end
    end

    private def build_http_client(host = DEFAULT_HOST, port = DEFAULT_PORT)
      HTTP::Client.new(host, port).tap do |c|
        configure_http_client(c)
      end
    end

    private def configure_http_client(client : HTTP::Client)
      client.connect_timeout = open_timeout
      client.read_timeout = read_timeout
      client.write_timeout = write_timeout
      client
    end

    private def proxy_host
      proxy_uri.try(&.host)
    end

    private def proxy_port
      proxy_uri.try(&.port)
    end
  end
end
