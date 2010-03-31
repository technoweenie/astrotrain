require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class Astrotrain::ApiTest < Astrotrain::ApiTestCase
  before :all do
    @filename1 = Astrotrain::Message.queue("boo!")
    @filename2 = Astrotrain::Message.queue("foo!")
  end

  it "counts queue" do
    get '/queue_size'
    assert_equal '2', last_response.body
  end

  it "lists queue files" do
    get '/queue'
    files = last_response.body.split("\n")
    assert_equal 2, files.size
    assert files.include?(File.basename(@filename1))
    assert files.include?(File.basename(@filename2))
  end

  it "reads queue file" do
    get "/queue/#{File.basename(@filename1)}"
    assert_equal 'boo!', last_response.body
  end

  it "does not read missing file" do
    get "/queue//etc/passwd"
    assert_equal "\"etc/passwd\" was not found.", last_response.body
  end
end

