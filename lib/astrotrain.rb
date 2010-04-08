module Astrotrain
  VERSION = '0.6.0'

  class << self
    attr_accessor :root, :lib_root, :callbacks
  end

  def self.load(root = Dir.pwd)
    self.root     = File.expand_path(root)
    self.lib_root = File.expand_path(File.dirname(__FILE__))
    yield if block_given?
    require 'tmail'
    autoload :Attachment, 'astrotrain/attachment'
    autoload :Message,    'astrotrain/message'
    autoload :Mail,       'astrotrain/mail'
  end
end