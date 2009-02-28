class Mapping
  class HttpPost < Transport
    def process
      return unless Transport.processing
      RestClient.post @mapping.destination, post_fields
    end

    def post_fields
      @post_fields ||= begin
        fields = {:subject => @message.subject, :to => @recipient, :from => @message.sender, :body => @message.body}
        @message.attachments.each_with_index do |att, index|
          fields[:"attachments_#{index}"] = att
        end
        fields
      end
    end
  end
end