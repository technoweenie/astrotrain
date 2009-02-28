class Mapping
  class HttpPost < Transport
    def process
      return unless Transport.processing
      RestClient.post @mapping.destination, fields
    end

    def fields
      super
      @message.attachments.each_with_index do |att, index|
        @fields[:"attachments_#{index}"] = att
      end
      @fields
    end
  end
end