module Astrotrain
  VERSION = '0.6.0'

  autoload :Attachment, 'astrotrain/attachment'
  autoload :Message,    'astrotrain/message'
  autoload :Mail,       'astrotrain/mail'

  # Transports are responsible for getting this email where it is supposed
  # to go.
  #
  # All Transports need to conform to this API:
  #
  #   Transports::HttpPost.process(address, message, main_recipient)
  #
  module Transports
    autoload :HttpPost, 'astrotrain/transports/http_post'
  end
end