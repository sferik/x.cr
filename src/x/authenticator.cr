module X
  class Authenticator
    AUTHENTICATION_HEADER = "Authorization"

    def header(request : HTTP::Request?)
      {AUTHENTICATION_HEADER => ""}
    end
  end
end
