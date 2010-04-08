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
        all_emails = message.recipients - [recipient]
        h = {:subject => message.subject, :to => recipient, :from => message.sender, 
             :body => message.body, :emails => all_emails.join(", "), :html => message.html,
             :headers => message.headers, :attachments => {}}
        message.attachments.each_with_index do |a, i|
          h[:attachments][i] = a
        end
        h.delete(:attachments) if h[:attachments].empty?
        h
      end
    end
  end
end