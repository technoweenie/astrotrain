class Mapping
  class HttpPost < Transport
    @@headers = {'Content-Type' => 'application/json'}

    def process
      return unless Transport.processing
      RestClient.post @mapping.destination, post_fields, @@headers
    end

    def post_fields
      @post_fields ||= {:subject => @message.subject, :to => @message.recipient(@mapping.recipient_header_order), :from => @message.sender, :body => @message.body}
    end
  end
end