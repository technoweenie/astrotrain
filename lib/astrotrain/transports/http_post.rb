require 'restclient'

module Astrotrain
  module Transports
    module HttpPost
      # Sends the message to the given address.
      #
      # url       - String address of the recipient service
      # message   - Astrotrain::Message instance
      # recipient - optional String email of the main recipient
      #
      # Returns a RestClient::Response object for responses between 200..206
      # Raises RestClient::Exception for any code not between 200..206 or 301..302
      def self.process(url, message, recipient = nil)
        recipient ||= message.recipients.first
        RestClient.post url, create_hash(message, recipient)
      end

      # Creates a param hash for RestClient.
      #
      # message   - Astrotrain::Message instance
      # recipient - String email of the main recipient.
      #
      # Returns a Hash for RestClient.post
      def self.create_hash(message, recipient)
        h = {:subject => message.subject, :to => {}, :from => {}, :cc => {},
             :body => message.body, :emails => message.recipients.join(", "), :html => message.html,
             :headers => message.headers, :attachments => {}}
        [:to, :from, :cc].each do |key|
          message.send(key).each_with_index do |addr, i|
            h[key][i] = {:name => addr.display_name, :address => addr.address}
          end
        end
        message.attachments.each_with_index do |a, i|
          h[:attachments][i] = a
        end
        [:attachments, :to, :from, :cc].each do |key|
          h.delete(key) if h[key].empty?
        end
        h
      end
    end
  end
end