module Astrotrain
  class << self
    attr_accessor :root, :lib_root
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

private
  def self.load_dependencies
    require 'rubygems'
    gem 'addressable',   '2.0.2'
    gem "tmail",         "1.2.3.1"
    gem "xmpp4r-simple", "0.8.8"

    dm_ver = "0.9.11"
    gem "dm-core",        dm_ver # The datamapper ORM
    gem "dm-aggregates",  dm_ver # Provides your DM models with count, sum, avg, min, max, etc.
    gem "dm-timestamps",  dm_ver # Automatically populate created_at, created_on, etc. when those properties are present.
    gem "dm-types",       dm_ver # Provides additional types, including csv, json, yaml.
    gem "dm-validations", dm_ver # Validation framework

    $LOAD_PATH.unshift File.join(lib_root, 'vendor', 'rest-client', 'lib')

    %w(dm-core dm-aggregates dm-timestamps dm-types dm-validations xmpp4r-simple tmail rest_client).each do |lib|
      require lib
    end
  end
end