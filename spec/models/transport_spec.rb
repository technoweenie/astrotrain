require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Mapping::HttpPost do
  before :all do
    @post    = 'http://example.com'
    @message = Message.parse(mail(:custom))
    @mapping = Mapping.new(:destination => @post, :transport => 'http_post')
  end

  before do
    @mapping.recipient_header_order = 'delivered_to,original_to,to'
    @trans   = Mapping::HttpPost.new(@message, @mapping)
  end

  it "sets #post_fields with default recipient_header_order" do
    @mapping.recipient_header_order = ''
    @trans.post_fields.should == {:subject => @message.subject, :from => @message.sender, :to => @message.recipient(%w(original_to)), :body => @message.body}
  end

  it "sets #post_fields" do
    @trans.post_fields.should == {:subject => @message.subject, :from => @message.sender, :to => @message.recipient(%w(delivered_to)), :body => @message.body}
  end

  it "sets post_fields with mapping separator set" do
    @message = Message.parse(mail(:reply))
    @mapping.separator = "=" * 5
    @trans   = Mapping::HttpPost.new(@message, @mapping)
    @trans.post_fields[:body].should == "blah blah"
  end

  describe "when processing" do
    before do
      Mapping::HttpPost.stub!(:new).and_return(@trans)
    end

    it "makes http post request" do
      RestClient.should_receive(:post).with(@mapping.destination, @trans.post_fields, 'Content-Type' => 'application/json')
      @trans.process
    end

    it "makes http post request from Transport" do
      RestClient.should_receive(:post).with(@mapping.destination, @trans.post_fields, 'Content-Type' => 'application/json')
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
    @message = Message.parse(mail(:custom))
    @mapping = Mapping.new(:destination => @dest, :transport => 'jabber')
  end

  before do
    @mapping.recipient_header_order = 'delivered_to,original_to,to'
    @trans   = Mapping::Jabber.new(@message, @mapping)
  end

  it "sets #content with default recipient_header_order" do
    @mapping.recipient_header_order = ''
    @trans.content.should == "From: %s\nTo: %s\nSubject: %s\n%s" % [@message.sender, @message.recipient(%w(original_to)), @message.subject, @message.body]
  end

  it "sets #content" do
    @trans.content.should == "From: %s\nTo: %s\nSubject: %s\n%s" % [@message.sender, @message.recipient(%w(delivered_to)), @message.subject, @message.body]
  end

  it "sets content with mapping separator set" do
    @message = Message.parse(mail(:reply))
    @mapping.separator = "=" * 5
    @trans   = Mapping::Jabber.new(@message, @mapping)
    @trans.content.should == "From: %s\nTo: %s\nSubject: %s\n%s" % [@message.sender, @message.recipient(%w(delivered_to)), @message.subject, "blah blah"]
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