require 'tmail'

module Astrotrain
  VERSION = '0.6.0'

  autoload :Attachment, 'astrotrain/attachment'
  autoload :Message,    'astrotrain/message'
  autoload :Mail,       'astrotrain/mail'
end