require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Mapping::HttpPost do
  before :all do
    @post    = 'http://example.com'
    @message = Message.parse(mail(:custom))
    @mapping = Mapping.new(:destination => @post, :transport => 'http_post')
  end

  before do
    @trans   = Mapping::HttpPost.new(@message, @mapping, @message.recipient(%w(delivered_to)))
  end

  it "sets #fields" do
    @trans.fields.should == {:subject => @message.subject, :from => @message.sender, :to => @message.recipient(%w(delivered_to)), :body => @message.body, :emails => @message.recipients(%w(original_to to))}
  end

  it "adds attachments to #fields" do
    @multipart = Message.parse(mail(:multipart))
    @trans     = Mapping::HttpPost.new(@multipart, @mapping, @multipart.recipient)
    @trans.fields.should == {:subject => @multipart.subject, :from => @multipart.sender, :to => @multipart.recipient, :body => @multipart.body, :attachments_0 => @multipart.attachments.first, :emails => []}
  end

  it "sets fields with mapping separator set" do
    @message = Message.parse(mail(:reply))
    @mapping.separator = "=" * 5
    @trans   = Mapping::HttpPost.new(@message, @mapping, @message.recipient)
    @trans.fields[:body].should == "blah blah"
  end

  describe "when processing" do
    before do
      Mapping::HttpPost.stub!(:new).and_return(@trans)
    end

    it "makes http post request" do
      RestClient.should_receive(:post).with(@mapping.destination, @trans.fields)
      @trans.process
    end

    it "makes http post request from Transport" do
      RestClient.should_receive(:post).with(@mapping.destination, @trans.fields)
      Mapping::Transport.process(@message, @mapping, @message.recipient)
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
    @trans   = Mapping::Jabber.new(@message, @mapping, @message.recipient(%w(delivered_to)))
  end

  it "sets #content" do
    @trans.content.should == "From: %s\nTo: %s\nSubject: %s\nEmails: %s\n%s" % [@message.sender, @message.recipient(%w(delivered_to)), @message.subject, @message.recipients(%w(original_to to)) * ", ", @message.body]
  end

  it "sets content with mapping separator set" do
    @message = Message.parse(mail(:reply))
    @mapping.separator = "=" * 5
    @trans   = Mapping::Jabber.new(@message, @mapping, @message.recipient(%w(delivered_to)))
    @trans.content.should == "From: %s\nTo: %s\nSubject: %s\nEmails: %s\n%s" % [@message.sender, @message.recipient(%w(delivered_to)), @message.subject, '', "blah blah"]
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
      Mapping::Transport.process(@message, @mapping, @message.recipient(%w(delivered_to)))
    end

    before :all do
      Mapping::Transport.processing = true
    end

    after :all do
      Mapping::Transport.processing = false
    end
  end
end