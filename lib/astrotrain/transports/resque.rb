require 'resque'

module Astrotrain
  module Transports
    module Resque
      # resque://QUEUE/KLASS
      Astrotrain::Transports::MAP[:resque] = self

      # Public: Sends the message to the given address.
      #
      # message   - Astrotrain::Message instance
      # url       - String address of the Resque in this form:
      #             "QUEUE/KLASS"
      # options   - Optional Hash:
      #             :recipient - String email of the main recipient
      #             :extra     - Hash to be merged with the payload
      #
      # Returns a queued Resque::Job instance.
      def self.deliver(message, url, options = {})
        recipient = options[:recipient] || message.recipients.first
        uri       = url.is_a?(Addressable::URI) ?
          url :
          Addressable::URI.parse(url)
        path = uri.path.dup
        path.sub! /^\//, ''
        queue, *job = path.split("/")
        if qu = uri.host
          job.unshift(queue)
          queue = qu
        end
        payload = create_hash(message, recipient)
        if extra = options[:extra]
          payload.update(extra)
        end
        ::Resque::Job.create(queue, job.join("/"), payload)
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

      # kept for backwards compatibility
      def self.process(url, message, recipient = nil, extra = nil)
        deliver(message, url, :recipient => recipient, :extra => extra)
      end
    end
  end
end

