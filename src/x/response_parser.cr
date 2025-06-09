require "http/client"
require "json"
require "./errors"

module X
  class ResponseParser
    ERROR_MAP = {
      400 => BadRequest,
      401 => Unauthorized,
      403 => Forbidden,
      404 => NotFound,
      406 => NotAcceptable,
      409 => ConnectionException,
      410 => Gone,
      413 => PayloadTooLarge,
      422 => UnprocessableEntity,
      429 => TooManyRequests,
      500 => InternalServerError,
      502 => BadGateway,
      503 => ServiceUnavailable,
      504 => GatewayTimeout,
    }

    def parse(response : HTTP::Client::Response, array_class : Class = Array, object_class : Class = Hash)
      raise error(response) unless response.status_code.in?(200..299)
      return nil if response.status_code == 204
      begin
        JSON.parse(response.body)
      rescue JSON::ParseException
        nil
      end
    end

    private def error(response : HTTP::Client::Response)
      error_class(response).new(response)
    end

    private def error_class(response : HTTP::Client::Response)
      ERROR_MAP[response.status_code] || HTTPError
    end
  end
end
