$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require "rubygems"
require "context"
require 'rr'
require 'astrotrain'

Astrotrain.load File.dirname(__FILE__) do
  DataMapper.setup(:default, {
    :adapter  => "mysql",
    :database => "astrotrain_test",
    :username => "root",
    :host     => "localhost"
  })
end

class Astrotrain::TestCase < Test::Unit::TestCase
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

Astrotrain::LoggedMail.log_path = Astrotrain.root / 'messages'
FileUtils.rm_rf   Astrotrain::LoggedMail.log_path
FileUtils.mkdir_p Astrotrain::LoggedMail.log_path

begin
  require 'ruby-debug'
  Debugger.start
rescue LoadError
end