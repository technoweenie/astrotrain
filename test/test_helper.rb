$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'rr'
require 'astrotrain'
require 'test/unit'

module Astrotrain
  load File.dirname(__FILE__)

  Message.queue_path = File.join(root, 'fixtures', 'queue')
  FileUtils.rm_rf   Message.queue_path
  FileUtils.mkdir_p Message.queue_path
end

class Test::Unit::TestCase
  include RR::Adapters::RRMethods

  ##
  # test/spec/mini
  # http://gist.github.com/307649
  # chris@ozmm.org
  #
  def self.test(name, &block) 
    define_method("test_#{name.gsub(/\W/,'_')}", &block) 
  end
  def self.xtest(*args) end
  def self.setup(&block)    define_method(:setup,    &block) end
  def self.teardown(&block) define_method(:teardown, &block) end

  def mail(filename)
    IO.read(File.join(File.dirname(__FILE__), 'fixtures', "#{filename}.txt"))
  end
end

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
end