require "./authenticator.cr"

module X
  class BearerTokenAuthenticator < Authenticator
    property bearer_token : String

    def initialize(@bearer_token : String)
    end

    def header(_request : HTTP::Request?)
      {AUTHENTICATION_HEADER => "Bearer #{bearer_token}"}
    end
  end
end
