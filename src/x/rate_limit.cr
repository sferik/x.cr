require "http/client"

module X
  class RateLimit
    enum Type
      RateLimit
      AppLimit24Hour
      UserLimit24Hour

      def header_prefix
        case self
        when RateLimit
          "rate-limit"
        when AppLimit24Hour
          "app-limit-24hour"
        when UserLimit24Hour
          "user-limit-24hour"
        end
      end
    end

    TYPES = Type.values

    property type : Type
    property response : HTTP::Client::Response

    def initialize(type : Type, @response : HTTP::Client::Response)
      @type = type
    end

    def initialize(type : String, response : HTTP::Client::Response)
      initialize(self.class.parse_type(type), response)
    end

    private def self.parse_type(type : String) : Type
      case type
      when "rate-limit"        then Type::RateLimit
      when "app-limit-24hour"  then Type::AppLimit24Hour
      when "user-limit-24hour" then Type::UserLimit24Hour
      else
        raise ArgumentError.new("Invalid rate limit type: #{type}")
      end
    end

    def limit
      response.headers["x-#{type.header_prefix}-limit"].to_i
    end

    def remaining
      response.headers["x-#{type.header_prefix}-remaining"].to_i
    end

    def reset_at
      Time.unix(response.headers["x-#{type.header_prefix}-reset"].to_i)
    end

    def reset_in
      d = reset_at - Time.utc
      d.total_seconds.ceil.to_i.clamp(0, Int32::MAX)
    end

    def retry_after
      reset_in
    end
  end
end
