class Mapping
  class Transport
    class << self
      attr_accessor :processing
    end
    self.processing = false

    attr_reader :message, :mapping

    def self.process(message, mapping, recipient)
      case mapping.transport
        when 'http_post' then HttpPost.process(message, mapping, recipient)
        when 'jabber'    then Jabber.process(message, mapping, recipient)
      end
    end

    def initialize(message, mapping, recipient)
      message.body = mapping.find_reply_from(message.body)
      @message     = message
      @mapping     = mapping
      @recipient   = recipient
    end

    def process
    end

    def fields
      @fields ||= begin
        {:subject => @message.subject, :to => @recipient, :from => @message.sender, :body => @message.body}
      end
    end

    def self.inherited(child)
      super
      class << child
        def process(message, mapping, recipient)
          new(message, mapping, recipient).process
        end
      end
    end
  end
end