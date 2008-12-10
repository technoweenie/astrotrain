class Mapping
  class HttpPost < Transport
    @@headers = {'Content-Type' => 'application/json'}

    def process
      return unless Transport.processing
      RestClient.post @mapping.destination, post_fields, @@headers
    end

    def post_fields
      @post_fields ||= begin
        fields = {:subject => @message.subject, :to => @message.recipient(@mapping.recipient_header_order), :from => @message.sender, :body => @message.body}
        @message.attachments.each_with_index do |att, index|
          fields[:"attachments_#{index}"] = att
        end
        fields
      end
    end
  end
end