path = File.join(File.dirname(__FILE__), '..')
$LOAD_PATH.unshift File.join(path, 'lib')
require 'astrotrain'

Astrotrain.load path do
  DataMapper.setup(:default, {
    :adapter  => "mysql",
    :database => "astrotrain",
    :username => "root",
    :host     => "localhost"
  })
end