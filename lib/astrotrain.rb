module Astrotrain
  VERSION = '0.6.0'

  require 'astrotrain/attachment'
  require 'astrotrain/message'

  # Processes an Astrotrain message.
  #
  # transport_key - Either a symbol mapping to a Transport class, or a 
  #                 Transport class.
  # destination   - String destination (URL or address) for the message.
  # message       - Astrotrain::Message instance.
  # options       - Optional hash of options:
  #                 :recipient - The main String recipient of the email.
  #                 :payload   - Optional hash to be sent with the request.
  #
  # Returns nothing.
  def self.process(transport_key, destination, message, options = {})
    transport = if transport_key.respond_to?(:process)
      transport_key
    else
      klass = Transports::MAP[transport_key]
      klass || raise(ArgumentError, "invalid transport: #{transport_key}")
    end
    transport.process(destination, message, options[:recipient], options[:payload])
  end

  # Transports are responsible for getting this email where it is supposed
  # to go.
  #
  # All Transports should conform to this API:
  #
  #   Transports::HttpPost.process(address, message, main_recipient, extra_payload={})
  #
  module Transports
    MAP = {}
    autoload :HttpPost, 'astrotrain/transports/http_post'
    autoload :Resque,   'astrotrain/transports/resque'
  end
end
