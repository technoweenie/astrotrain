require File.join(File.dirname(__FILE__), "test_helper")

class Astrotrain::MessageTest < Astrotrain::TestCase
  describe "mapping" do
    describe "against default domain" do
      before :all do
        Astrotrain::Mapping.transaction do
          Astrotrain::LoggedMail.all.destroy!
          Astrotrain::Mapping.all.destroy!
          @mapping  = Astrotrain::Mapping.create!(:email_user => 'xyz')
          @mapping2 = Astrotrain::Mapping.create!(:email_user => 'xyz',  :email_domain => 'sample.com')
        end
      end

      describe "without mapping" do
        it "doesn't log message" do
          @msg = Astrotrain::Message.receive(mail(:basic))
          @log = Astrotrain::LoggedMail.first
          assert_nil @log
        end

        it "logs message if Astrotrain::LoggedMail.log_processed" do
          begin
            Astrotrain::LoggedMail.log_processed = true
            @msg = Astrotrain::Message.receive(mail(:basic))
            @log = Astrotrain::LoggedMail.first
            assert @log
            assert @log.error_message.blank?
          ensure
            Astrotrain::LoggedMail.log_processed = false
          end
        end
      end

      describe "erroring" do
        before do
          Astrotrain::LoggedMail.all.destroy!
        end

        it "logs message without mappping" do
          stub(Astrotrain::Mapping).match { raise RuntimeError }
          @msg = Astrotrain::Message.receive(mail(:basic))
          @log = Astrotrain::LoggedMail.first
          assert @log
          assert_nil @log.delivered_at
          assert_match /RuntimeError/, @log.error_message
          assert_nil @log.mapping
        end

        it "logs message with mappping" do
          stub(Astrotrain::Mapping).match {@mapping}
          stub(@mapping).process { raise RuntimeError }
          @msg = Astrotrain::Message.receive(mail(:basic))
          @log = Astrotrain::LoggedMail.first
          assert @log
          assert_nil @log.delivered_at
          assert_match /RuntimeError/, @log.error_message
          assert_equal @mapping, @log.mapping
        end
      end

      describe "with mapping" do
        before :all do
          @msg = Astrotrain::Message.receive(mail(:mapped))
          @log = Astrotrain::LoggedMail.first
        end

        it "does not log message" do
          assert_nil @log
        end
      end
    end
  end

  describe "parsing" do
    before :all do
      @body = "---------- Forwarded message ----------\nblah blah"
    end

    describe "basic, single sender/recipient" do
      before :all do
        @raw     = mail(:basic)
        @message = Astrotrain::Message.parse(@raw)
      end

      it "parses TMail::Mail headers" do
        expected = {'mime-version' => '1.0', 'content-type' => 'text/plain; charset=ISO-8859-1', 'to' => 'Processor <processor@astrotrain.com>',
          'x-custom' => 'reply', 'content-transfer-encoding' => '7bit', 'content-disposition' => 'inline', 'message-id' => '<a16be7390810161014n52b603e9k1aa6bb803c6735aa@mail.gmail.com>'}
        assert_equal expected, @message.headers
      end

      it "#parse parses TMail::Mail object from raw text" do
        assert_kind_of TMail::Mail, @message.mail
      end

      it "recognizes Delivered-To and To: headers as recipients" do
        assert_equal %w(processor@astrotrain.com), @message.recipients
      end

      it "recognizes From: header as sender" do
        assert_equal %(Bob <user@example.com>), @message.sender
      end

      it "recognizes Subject: header" do
        assert_equal 'Fwd: blah blah', @message.subject
      end

      it "recognizes message body" do
        assert_equal @body, @message.body
      end

      it "retains raw message" do
        assert_equal @raw, @message.raw
      end
    end
    
    describe "iso 8859 1 encoded headers" do
      before :all do
        @raw     = mail("iso-8859-1")
        @message = Astrotrain::Message.parse(@raw)
      end

      it "recognizes From: header with strange encoding" do
        assert_equal %(Matthéw <user@example.com>), @message.sender
      end
    end

    describe "gb2312 encoded body" do
      before :all do
        @raw     = mail("gb2312_encoding")
        @message = Astrotrain::Message.parse(@raw)
      end

      it "converts to UTF-8" do
        assert_equal "Dear Sirs, \r\nWe are given to understand that you are  Manufacturer of  plstic  Bottles\r\nAdd： blah China", 
          @message.body
      end
    end

    describe "gb2312 encoded body with invalid charset in mime version header" do
      before :all do
        @raw     = mail("gb2312_encoding_invalid")
        @message = Astrotrain::Message.parse(@raw)
      end

      it "converts to UTF-8" do
        assert_equal "Dear Sirs, \r\nWe are given to understand that you are  Manufacturer of  plstic  Bottles\r\nAdd： blah China",
          @message.body
      end
    end

    describe "utf 8 encoded headers" do
      before :all do
        @raw     = mail("utf-8")
        @message = Astrotrain::Message.parse(@raw)
      end
      
      it "recognizes From: header with strange encoding" do
        assert_equal %(isnard naiké <user@example.com>), @message.sender
      end
    end

    describe "multipart message with name property on Content Type" do
      before :all do
        @raw     = mail(:multipart)
        @message = Astrotrain::Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        assert_kind_of TMail::Mail, @message.mail
      end

      it "recognizes Delivered-To/To: headers as recipient" do
        assert_equal %w(foo@example.com), @message.recipients
      end

      it "recognizes message body" do
        assert_equal "Testing out rich emails with attachments!\nThis one has a name property on Content-Type.\n[state:hold responsible:rick]\n\n",
          @message.body
      end

      it "retrieves attachments" do
        assert_equal 1, @message.attachments.size
      end

      it "retrieves attachment filename" do
        assert_equal 'bandit.jpg', @message.attachments.first.filename
      end

      it "retrieves attachment content_type" do
        assert_equal 'image/jpeg', @message.attachments.first.content_type
      end
    end

    describe "multipart message with filename property on Content Disposition" do
      before :all do
        @raw     = mail(:multipart2)
        @message = Astrotrain::Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        assert_kind_of TMail::Mail, @message.mail
      end

      it "recognizes Delivered-To/To: headers as recipient" do
        assert_equal %w(foo@example.com), @message.recipients
      end

      it "recognizes message body" do
        assert_equal "Testing out rich emails with attachments!\nThis one has NO name property on Content-Type.\n[state:hold responsible:rick]\n\n", 
          @message.body
      end

      it "retrieves attachments" do
        assert_equal 1, @message.attachments.size
      end

      it "retrieves attachment filename" do
        assert_equal 'bandit.jpg', @message.attachments.first.filename
      end

      it "retrieves attachment content_type" do
        assert_equal 'image/jpeg', @message.attachments.first.content_type
      end
    end

    describe "apple multipart message" do
      before :all do
        @raw     = mail(:apple_multipart)
        @message = Astrotrain::Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        assert_kind_of TMail::Mail, @message.mail
      end

      it "recognizes To: header as recipient" do
        assert_equal %w(foo@example.com), @message.recipients
      end

      it "recognizes message body" do
        assert_equal "Let's have a test here:\r\n\r\n\r\n\nYum\r\n\r\n\r\nOn Feb 10, 2009, at 3:37 PM, Tender Support wrote:\r\n\r\n> // Add your reply above here\r\n> ==================================================\r\n> From: Tyler Durden\r\n> Subject: Email attachments and file upload\r\n>\r\n> not at the moment ... let me test\r\n>\r\n> View this Discussion online: http://foobar.com\r\n> .\r\n\r\n\r\n\r\n\r\n--Apple-Mail-7-451386929--", 
          @message.body
      end

      it "retrieves attachments" do
        assert_equal 1, @message.attachments.size
      end

      it "retrieves attachment filename" do
        assert_equal 'logo.gif', @message.attachments.first.filename
      end

      it "retrieves attachment content_type" do
        assert_equal 'image/gif', @message.attachments.first.content_type
      end
    end

    describe "multiple sender/recipients" do
      before :all do
        @raw     = mail(:multiple)
        @message = Astrotrain::Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        assert_kind_of TMail::Mail, @message.mail
      end

      it "recognizes To: headers as recipients" do
        assert_equal %w(processor@astrotrain.com other@example.com), @message.recipients
      end

      it "recognizes To: headers as recipients with custom header order" do
        assert_equal %w(other@example.com processor@astrotrain.com), @message.recipients(%w(to original_to delivered_to))
      end

      it "recognizes From: header as sender" do
        assert_equal %(user@example.com, boss@example.com), @message.sender
      end

      it "recognizes Subject: header" do
        assert_equal 'Fwd: blah blah', @message.subject
      end

      it "recognizes message body" do
        assert_equal @body, @message.body
      end

      it "retains raw message" do
        assert_equal @raw, @message.raw
      end
    end

    describe "recipients in the body" do
      before :all do
        @raw     = mail(:multiple_with_body_recipients)
        @message = Astrotrain::Message.parse(@raw)
      end

      it "recognizes in-body emails and To: headers as recipients" do
        assert_equal %w(processor+foobar@astrotrain.com processor+blah@astrotrain.com processor@astrotrain.com other@example.com), 
          @message.recipients
      end
    end

    describe "with only HTML body" do
      before :all do
        @raw     = mail(:html)
        @message = Astrotrain::Message.parse(@raw)
      end

      it "parses emtpy body" do
        assert_equal '', @message.body
      end

      it "parses HTML body" do
        assert_equal "<p>ABC</p>\n------", @message.html
      end
    end

    describe "with X Original To header" do
      before :all do
        @raw     = mail(:custom)
        @message = Astrotrain::Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        assert_kind_of TMail::Mail, @message.mail
      end

      it "recognizes X-Original-to: header as recipient" do
        assert_equal %w(processor-reply-57@custom.com processor-delivered@astrotrain.com processor@astrotrain.com), @message.recipients
      end

      it "recognizes Delivered-To: header as recipient with custom header order" do
        assert_equal %w(processor-delivered@astrotrain.com processor-reply-57@custom.com processor@astrotrain.com), @message.recipients(%w(delivered_to original_to to))
      end

      it "recognizes To: header as recipient with custom header order" do
        assert_equal %w(processor@astrotrain.com processor-reply-57@custom.com processor-delivered@astrotrain.com), @message.recipients(%w(to original_to delivered_to))
      end

      it "recognizes From: header as sender" do
        assert_equal %(user@example.com, boss@example.com), @message.sender
      end

      it "recognizes Subject: header" do
        assert_equal 'Fwd: blah blah', @message.subject
      end

      it "recognizes message body" do
        assert_equal @body, @message.body
      end

      it "retains raw message" do
        assert_equal @raw, @message.raw
      end
    end

    describe "with multiple Delivered To headers" do
      before :all do
        @raw     = mail(:multiple_delivered_to)
        @message = Astrotrain::Message.parse(@raw)
      end

      it "recognizes Delivered-to: header as recipient" do
        assert_equal %w(processor-reply-57@custom.com processor-delivered@astrotrain.com processor@astrotrain.com), @message.recipients
      end
    end
  end

  describe "queueing" do
    it "writes contents queue path" do
      filename = Astrotrain::Message.queue("boo!")
      assert_equal 'boo!', IO.read(filename)
    end
  end
end