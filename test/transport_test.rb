require File.join(File.dirname(__FILE__), "test_helper")

class Astrotrain::TransportTest < Astrotrain::TestCase
  describe "HttpPost" do
    before :all do
      @post    = 'http://example.com'
      @message = Astrotrain::Message.parse(mail(:custom))
      @mapping = Astrotrain::Mapping.new(:destination => @post, :transport => 'http_post')
    end

    before do
      @trans           = Astrotrain::Mapping::HttpPost.new(@message, @mapping, @message.recipients(%w(delivered_to)).first)
      @expected_fields = @trans.fields.merge(:emails => @message.recipients(%w(original_to to)) * ",")
    end

    it "sets #fields" do
      expected = {:subject => @message.subject, :from => @message.sender, :to => @message.recipients(%w(delivered_to)).first, :body => @message.body, :html => @message.html, :emails => @message.recipients(%w(original_to to)),
        "headers[reply-to]" => "reply-to-me@example.com", 'headers[message-id]' => '<a16be7390810161014n52b603e9k1aa6bb803c6735aa@mail.gmail.com>', 'headers[to]' => "processor@astrotrain.com",
        "headers[mime-version]"=>"1.0", "headers[content-type]"=>"text/plain; charset=ISO-8859-1", "headers[content-disposition]"=>"inline", "headers[content-transfer-encoding]"=>"7bit"}
      assert_equal expected, @trans.fields
    end

    it "adds attachments to #fields" do
      @multipart = Astrotrain::Message.parse(mail(:multipart))
      @trans     = Astrotrain::Mapping::HttpPost.new(@multipart, @mapping, @multipart.recipients.first)
      assert_equal @multipart.attachments.first, @trans.fields[:attachments_0]
    end

    it "sets fields with mapping separator set" do
      @message = Astrotrain::Message.parse(mail(:reply))
      @mapping.separator = "=" * 5
      @trans   = Astrotrain::Mapping::HttpPost.new(@message, @mapping, @message.recipients.first)
      assert_equal "blah blah", @trans.fields[:body]
    end

    describe "when processing" do
      before do
        stub(Astrotrain::Mapping::HttpPost).new {@trans}
      end

      it "makes http post request" do
        mock(RestClient).post(@mapping.destination, @expected_fields)
        @trans.process
      end

      it "makes http post request from Transport" do
        mock(RestClient).post(@mapping.destination, @expected_fields)
        Astrotrain::Mapping::Transport.process(@message, @mapping, @message.recipients.first)
      end

      before :all do
        Astrotrain::Mapping::Transport.processing = true
      end

      after :all do
        Astrotrain::Mapping::Transport.processing = false
      end
    end
  end

  describe "jabber" do
    before :all do
      @dest    = 'foo@bar.com'
      @message = Astrotrain::Message.parse(mail(:custom))
      @mapping = Astrotrain::Mapping.new(:destination => @dest, :transport => 'jabber')
    end

    before do
      @trans   = Astrotrain::Mapping::Jabber.new(@message, @mapping, @message.recipients(%w(delivered_to)).first)
    end

    it "sets #content" do
      expected = "From: %s\nTo: %s\nSubject: %s\nEmails: %s\n%s" % [@message.sender, @message.recipients(%w(delivered_to)).first, @message.subject, @message.recipients(%w(original_to to)) * ", ", @message.body]
      assert_equal expected, @trans.content
    end

    it "sets content with mapping separator set" do
      @message = Astrotrain::Message.parse(mail(:reply))
      @mapping.separator = "=" * 5
      @trans   = Astrotrain::Mapping::Jabber.new(@message, @mapping, @message.recipients(%w(delivered_to)).first)
      expected = "From: %s\nTo: %s\nSubject: %s\nEmails: %s\n%s" % [@message.sender, @message.recipients(%w(delivered_to)).first, @message.subject, '', "blah blah"]
      assert_equal expected, @trans.content
    end

    describe "when processing" do
      before do
        @conn = Object.new
        stub(@trans).connection { @conn }
        stub(Astrotrain::Mapping::Jabber).new { @trans }
      end

      it "makes jabber delivery" do
        mock(@conn).deliver(@mapping.destination, @trans.content)
        @trans.process
      end

      it "makes jabber delivery from Transport" do
        mock(@conn).deliver(@mapping.destination, @trans.content)
        Astrotrain::Mapping::Transport.process(@message, @mapping, @message.recipients(%w(delivered_to)).first)
      end

      before :all do
        Astrotrain::Mapping::Transport.processing = true
      end

      after :all do
        Astrotrain::Mapping::Transport.processing = false
      end
    end
  end
end