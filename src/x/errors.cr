module X
  macro def_error(name, superclass)
    class {{name.id}} < {{superclass.id}}
    end
  end

  class Error < Exception
  end

  class HTTPError < Error
    property response : HTTP::Client::Response
    property code : Int32

    def initialize(@response : HTTP::Client::Response)
      @code = @response.status_code
      super error_message
    end

    private def error_message
      content_type = @response.headers["Content-Type"]?
      if content_type && content_type.starts_with?("application/json")
        body = JSON.parse(@response.body)
        if body["title"]? && body["detail"]?
          "#{body["title"]}: #{body["detail"]}"
        elsif body["error"]?
          body["error"].as_s
        elsif body["errors"]?.is_a?(Array)
          body["errors"].as_a.map { |e| e["message"].as_s }.join(", ")
        else
          @response.status_message
        end
      else
        @response.status_message
      end
    end
  end

  class ClientError < HTTPError
  end

  class ServerError < HTTPError
  end

  # error subclasses
  def_error BadRequest, ClientError
  def_error ConnectionException, ClientError
  def_error Forbidden, ClientError
  def_error Gone, ClientError
  def_error Unauthorized, ClientError
  def_error NotFound, ClientError
  def_error NotAcceptable, ClientError
  def_error PayloadTooLarge, ClientError
  def_error UnprocessableEntity, ClientError
  def_error NetworkError, Error
  def_error TooManyRedirects, Error
  def_error BadGateway, ServerError
  def_error InternalServerError, ServerError
  def_error ServiceUnavailable, ServerError
  def_error GatewayTimeout, ServerError

  class TooManyRequests < ClientError
    def rate_limit
      rate_limits.max_by(&.reset_at)
    end

    def rate_limits
      RateLimit::TYPES.compact_map do |type|
        if response.headers["x-#{type.header_prefix}-remaining"]? == "0"
          RateLimit.new(type, response)
        end
      end
    end

    def reset_at
      rate_limit.try(&.reset_at) || Time.unix(0)
    end

    def reset_in
      (reset_at - Time.utc).total_seconds.to_i
    end

    def retry_after
      reset_in
    end
  end
end
