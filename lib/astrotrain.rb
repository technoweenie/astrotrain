module Astrotrain
  VERSION = '0.6.0'

  require 'astrotrain/attachment'
  require 'astrotrain/message'

  # Transports are responsible for getting this email where it is supposed
  # to go.
  #
  # All Transports should conform to this API:
  #
  #   Transports::HttpPost.process(address, message, main_recipient)
  #
  module Transports
    autoload :HttpPost, 'astrotrain/transports/http_post'
  end
end