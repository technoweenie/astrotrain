$testing = true
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require "rubygems"
require "context"
require 'rr'
require 'astrotrain'
require 'astrotrain/api'
require 'sinatra/test'

module Astrotrain
  load File.dirname(__FILE__) do
    DataMapper.setup(:default, {
      :adapter  => "mysql",
      :database => "astrotrain_test",
      :username => "root",
      :host     => "localhost"
    })
  end

  LoggedMail.auto_migrate!
  Mapping.auto_migrate!

  LoggedMail.log_path = Astrotrain.root / 'messages'
  FileUtils.rm_rf   LoggedMail.log_path
  FileUtils.mkdir_p LoggedMail.log_path

  Message.queue_path = root / 'fixtures' / 'queue'
  FileUtils.rm_rf   Message.queue_path
  FileUtils.mkdir_p Message.queue_path

  class TestCase < Test::Unit::TestCase
    include RR::Adapters::RRMethods

    before do
      RR.reset
    end

    after do
      RR.verify
    end

    def mail(filename)
      IO.read(File.join(File.dirname(__FILE__), 'fixtures', "#{filename}.txt"))
    end
  end

  class ApiTestCase < TestCase
    include Sinatra::Test
  end
end

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
end