class Mapping
  class Transport
    class << self
      attr_accessor :processing
    end
    self.processing = false

    attr_reader :message, :mapping

    def self.process(message, mapping)
      case mapping.transport
        when 'http_post' then HttpPost.process(message, mapping)
        when 'jabber'    then Jabber.process(message, mapping)
      end
    end

    def initialize(message, mapping)
      message.body = mapping.find_reply_from(message.body)
      @message = message
      @mapping = mapping
    end

    def process
    end

    def self.inherited(child)
      super
      class << child
        def process(message, mapping)
          new(message, mapping).process
        end
      end
    end
  end
end