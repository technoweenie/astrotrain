$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'astrotrain'
require 'test/unit'

class Test::Unit::TestCase
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

  PARSED = {}
  def astrotrain(filename)
    PARSED[filename] ||= Astrotrain::Message.parse(mail(filename))
  end
end

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
end
