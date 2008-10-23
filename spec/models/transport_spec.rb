require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Mapping::HttpPost do
  before :all do
    @post    = 'http://example.com'
    @message = Message.parse(mail(:basic))
    @mapping = Mapping.new(:destination => @post, :transport => 'http_post')
    @trans   = Mapping::HttpPost.new(@message, @mapping)
  end

  it "sets #post_fields" do
    @trans.post_fields.should == {:subject => @message.subject, :from => @message.sender, :to => @message.recipient, :body => @message.body}
  end

  it "sets post_fields with mapping separator set" do
    @message = Message.parse(mail(:reply))
    @mapping.separator = "=" * 5
    @trans   = Mapping::HttpPost.new(@message, @mapping)
    @trans.post_fields[:body].should == "blah blah"
  end

  it "creates request object" do
    @trans.request.should be_kind_of(Curl::Easy)
    @trans.request.url.should == @post
  end

  describe "when processing" do
    before do
      @trans.request.stub!(:http_post)
      Mapping::HttpPost.stub!(:new).and_return(@trans)
    end

    it "makes http post request" do
      @trans.request.should_receive :http_post
      @trans.process
    end

    it "makes http post request from Transport" do
      @trans.request.should_receive :http_post
      Mapping::Transport.process(@message, @mapping)
    end

    before :all do
      Mapping::Transport.processing = true
    end

    after :all do
      Mapping::Transport.processing = false
    end
  end
end

describe Mapping::Jabber do
  before :all do
    @dest    = 'foo@bar.com'
    @message = Message.parse(mail(:basic))
    @mapping = Mapping.new(:destination => @dest, :transport => 'jabber')
    @trans   = Mapping::Jabber.new(@message, @mapping)
  end

  it "sets #content" do
    @trans.content.should == "From: %s\nTo: %s\nSubject: %s\n%s" % [@message.sender, @message.recipient, @message.subject, @message.body]
  end

  it "sets content with mapping separator set" do
    @message = Message.parse(mail(:reply))
    @mapping.separator = "=" * 5
    @trans   = Mapping::Jabber.new(@message, @mapping)
    @trans.content.should == "From: %s\nTo: %s\nSubject: %s\n%s" % [@message.sender, @message.recipient, @message.subject, "blah blah"]
  end

  describe "when processing" do
    before do
      Jabber::Simple.stub!(:new).and_return(mock("Jabber::Simple"))
      @trans.connection.stub!(:deliver)
      Mapping::Jabber.stub!(:new).and_return(@trans)
    end

    it "makes jabber delivery" do
      @trans.connection.should_receive :deliver
      @trans.process
    end

    it "makes jabber delivery from Transport" do
      @trans.connection.should_receive :deliver
      Mapping::Transport.process(@message, @mapping)
    end

    before :all do
      Mapping::Transport.processing = true
    end

    after :all do
      Mapping::Transport.processing = false
    end
  end
end