module Astrotrain
  VERSION = '0.6.0'

  require 'addressable/uri'
  require 'faraday'
  require 'astrotrain/attachment'
  require 'astrotrain/message'

  # Processes an Astrotrain message.
  #
  # message     - Astrotrain::Message instance.
  # destination - String URL to deliver the message.  The scheme selects
  #               which Transport module to use (http://, resque://)
  # options     - Optional hash of options:
  #               :recipient - The main String recipient of the email.
  #               :payload   - Optional hash to be sent with the request.
  #
  # Returns nothing.
  def self.deliver(message, destination, options = {})
    uri   = Addressable::URI.parse(destination.to_s)
    klass = Transports.load(uri.scheme)
    klass.deliver(message, destination, 
                  :recipient => options[:recipient],
                  :extra     => options[:payload])
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
      key   = key.to_sym if key
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
