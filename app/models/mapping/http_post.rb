class Mapping
  class HttpPost < Transport
    @@headers = {'Content-Type' => 'application/json'}

    def process
      return unless Transport.processing
      curl_params = post_fields.inject([]) do |params, (key, value)|
        value = value * "," if value.is_a?(Array)
        params << Curl::PostField.content(key.to_s, value)
      end
      request.http_post *curl_params
    end

    def request
      @request ||= Curl::Easy.new(@mapping.destination)
    end

    def post_fields
      @post_fields ||= {:subject => @message.subject, :to => @message.recipient, :from => @message.senders, :body => @message.body}
    end
  end
end