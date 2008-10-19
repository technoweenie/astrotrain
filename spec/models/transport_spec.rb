require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Mapping::HttpPost do
  before :all do
    @post    = 'http://example.com'
    @message = Message.parse(mail(:basic))
    @trans   = Mapping::HttpPost.new(@message, Mapping.new(:post_url => @post))
  end

  it "sets #post_fields" do
    @trans.post_fields.should == {:subject => @message.subject, :from => @message.senders, :to => @message.recipient, :body => @message.body}
  end

  it "creates request object" do
    @trans.request.should be_kind_of(Curl::Easy)
    @trans.request.url.should == @post
  end

  it "makes HTTP post request when processing" do
    begin
      Mapping::Transport.processing = true
      @trans.request.should_receive :http_post
      @trans.process
    ensure
      Mapping::Transport.processing = false
    end
  end
end

describe Mapping::Jabber do
  before :all do
    @dest    = 'foo@bar.com'
    @message = Message.parse(mail(:basic))
    @trans   = Mapping::Jabber.new(@message, Mapping.new(:post_url => @dest))
  end

  it "sets #content" do
    @trans.content.should == "From: %s\nTo: %s\nSubject: %s\n%s" % [@message.senders.join(", "), @message.recipient, @message.subject, @message.body]
  end

  it "delivers jabber message when processing" do
    begin
      @trans.stub!(:connection).and_return(mock("Jabber::Simple"))
      Mapping::Transport.processing = true
      @trans.connection.should_receive :deliver
      @trans.process
    ensure
      Mapping::Transport.processing = false
    end
  end
end