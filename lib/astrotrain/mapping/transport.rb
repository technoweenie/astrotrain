module Astrotrain
  class Mapping
    class Transport
      class << self
        attr_accessor :processing
      end

      # Enable this turn on processing.
      self.processing = false

      attr_reader :message, :mapping

      # process a given message against the mapping.  The mapping transport is checked,
      # and the appropirate transport class handles the request.
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
        raise UnimplementedError
      end

      def fields
        @fields ||= begin
          all_emails = @message.recipients - [@recipient]
          f = {:subject => @message.subject, :to => @recipient, :from => @message.sender, :body => @message.body, :emails => all_emails, :html => @message.html}
          @message.headers.each do |key, value|
            f["headers[#{key}]"] = value
          end
          f
        end
      end

      # defines custom #process class methods that instantiate the class and calls a #process instance method
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
end