module FbRuby
  
  class Exception < StandardError
    attr_reader :message
    
    def initialize(message = "Terjadi kesalahan :(")
      @message = message
    end
    
    def to_s
      return @message
    end
  end
  
  module Exceptions
    class AccountCheckPoint < FbRuby::Exception; end
    class LoginFailed < FbRuby::Exception; end
    class InvalidCookies < FbRuby::Exception; end
    class AccountTemporaryBanned < FbRuby::Exception; end
    class AccountDisabled < FbRuby::Exception; end
    class PageNotFound < FbRuby::Exception; end
    class SessionExpired < FbRuby::Exception; end
    class FacebookError < FbRuby::Exception; end
  end
end