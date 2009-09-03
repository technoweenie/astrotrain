require 'astrotrain'

Astrotrain.load do
  DataMapper.setup(:default, {
    :adapter  => "mysql",
    :database => "astrotrain",
    :username => "root",
    :host     => "localhost"
  })
end