require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class Astrotrain::ApiTest < Astrotrain::ApiTestCase
  before :all do
    @filename1 = Astrotrain::Message.queue("boo!")
    @filename2 = Astrotrain::Message.queue("foo!")
  end

  it "counts queue" do
    assert_equal '2', get("/queue_size").body
  end

  it "lists queue files" do
    files = get("/queue").body.split("\n")
    assert_equal 2, files.size
    assert files.include?(File.basename(@filename1))
    assert files.include?(File.basename(@filename2))
  end

  it "reads queue file" do
    assert_equal 'boo!', get("/queue/#{File.basename(@filename1)}").body
  end

  it "does not read missing file" do
    assert_equal "\"etc/passwd\" was not found.", get("/queue//etc/passwd").body
  end
end

