module Astrotrain
  CALLBACK_TYPES = [:pre_mapping, :pre_processing, :post_processing]
  class << self
    attr_accessor :root, :lib_root, :callbacks
  end

  def self.load(root = Dir.pwd)
    self.root     = File.expand_path(root)
    self.lib_root = File.expand_path(File.dirname(__FILE__))
    load_dependencies
    yield if block_given?
    %w(tmail message mapping logged_mail mapping/transport mapping/http_post mapping/jabber).each do |lib|
      require "astrotrain/#{lib}"
    end
    Astrotrain::Mail::ALLOW_MULTIPLE['delivered-to'] = true
  end

  def self.callback(name, *args, &block)
    found = callbacks[name]
    if block
      found << block
    else
      found.each { |cback| cback.call(*args) }
    end
    found
  end

  def self.clear_callbacks
    self.callbacks = CALLBACK_TYPES.inject({}) { |memo, ctype| memo.update(ctype => []) }
  end

  clear_callbacks

private
  # help me ryan tomayko, you're my only help
  def self.load_dependencies
    $LOAD_PATH.unshift File.join(lib_root, 'vendor', 'rest-client', 'lib')

    %w(dm-core dm-aggregates dm-timestamps dm-types dm-validations tmail rest_client).each do |lib|
      require lib
    end
  end
end