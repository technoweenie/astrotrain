require 'resque'

module Astrotrain
  module Transports
    module Resque
      Astrotrain::Transports::MAP[:resque] = self

      # Public: Sends the message to the given address.
      #
      # url       - String address of the Resque in this form:
      #             "QUEUE:KLASS"
      # message   - Astrotrain::Message instance
      # recipient - optional String email of the main recipient
      # extra     - Optional Hash to be merged with the payload
      #
      # Returns a queued Resque::Job instance.
      def self.process(destination, message, recipient = nil, extra = nil)
        recipient ||= message.recipients.first
        queue, *job = destination.split(":")
        payload     = create_hash(message, recipient)
        payload.update(extra) if extra
        ::Resque::Job.create(queue, job.join(":"), payload)
      end

      # Creates a param hash for RestClient.
      #
      # message   - Astrotrain::Message instance
      # recipient - String email of the main recipient.
      #
      # Returns a Hash for Resque.
      def self.create_hash(message, recipient)
        h = {:subject => message.subject, :to => [], :from => [], :cc => [],
             :body => message.body, :emails => message.recipients.join(", "), :html => message.html,
             :headers => message.headers}
        [:to, :from, :cc].each do |key|
          message.send(key).each_with_index do |addr, i|
            h[key] << {:name => addr.display_name, :address => addr.address}
          end
        end
        h
      end
    end
  end
end

