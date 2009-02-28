class Mapping
  class Jabber < Transport
    class << self
      attr_accessor :login, :password
    end

    def process
      return unless Transport.processing
      connection.deliver(@mapping.destination, content)
    end

    def connection
      @connection ||= ::Jabber::Simple.new(self.class.login, self.class.password)
    end

    def content
      @content ||= "From: %s\nTo: %s\nSubject: %s\nEmails: %s\n%s" % [fields[:from], fields[:to], fields[:subject], fields[:emails] * ", ", fields[:body]]
    end
  end
end