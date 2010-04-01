module Astrotrain
  class ProcessingCancelled < StandardError; end

  CALLBACK_TYPES = [:pre_mapping, :pre_processing, :post_processing]
  class << self
    attr_accessor :root, :lib_root, :callbacks
  end

  def self.load(root = Dir.pwd)
    self.root     = File.expand_path(root)
    self.lib_root = File.expand_path(File.dirname(__FILE__))
    yield if block_given?
    load_dependencies
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
    require 'rubygems'
    gem 'addressable',   '2.0.2'

    dm_ver = "0.9.11"
    gem "data_objects",   dm_ver
    gem "dm-core",        dm_ver # The datamapper ORM
    gem "dm-aggregates",  dm_ver # Provides your DM models with count, sum, avg, min, max, etc.
    gem "dm-timestamps",  dm_ver # Automatically populate created_at, created_on, etc. when those properties are present.
    gem "dm-types",       dm_ver # Provides additional types, including csv, json, yaml.
    gem "dm-validations", dm_ver # Validation framework

    $LOAD_PATH.unshift File.join(lib_root, 'vendor', 'rest-client', 'lib')

    %w(dm-core dm-aggregates dm-timestamps dm-types dm-validations tmail rest_client).each do |lib|
      require lib
    end
  end
end