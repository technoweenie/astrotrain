module Astrotrain
  VERSION = '0.6.0'

  require 'faraday'
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
      if !klass
        uri = Addressable::URI.parse(transport_key.to_s)
        if klass = uri.scheme && Transports.load(uri.scheme.to_sym)
          options     = message
          message     = destination
          destination = uri
        end
      end
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
    MAP = {:http => :http_post, :resque => :resque}

    def self.load(key)
      value = MAP[key]
      if !value
        raise ArgumentError, "No transport #{key.inspect} found in #{MAP.keys.inspect}"
      elsif value.is_a?(Module)
        value
      else
        require "astrotrain/transports/#{value}"
        MAP[key]
      end
    end
  end
end
