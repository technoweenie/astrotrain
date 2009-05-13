require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Message do
  describe "mapping" do
    describe "against default domain" do
      before :all do
        User.transaction do
          LoggedMail.all.destroy!
          User.all.destroy!
          Mapping.all.destroy!
          @user     = User.create!(:login => 'user')
          @mapping  = @user.mappings.create!(:user_id => @user.id, :email_user => 'xyz')
          @mapping2 = @user.mappings.create!(:user_id => @user.id, :email_user => 'xyz',  :email_domain => 'sample.com')
        end
      end

      describe "without mapping" do
        before :all do
          @msg = Message.receive(mail(:basic))
          @log = LoggedMail.first
        end

        it "doesn't log message" do
          @log.should == nil
        end
      end

      describe "erroring" do
        before do
          LoggedMail.all.destroy!
        end

        it "logs message without mappping" do
          Mapping.stub!(:match).and_raise RuntimeError
          @msg = Message.receive(mail(:basic))
          @log = LoggedMail.first
          @log.should_not           == nil
          @log.delivered_at.should  == nil
          @log.error_message.should =~ /RuntimeError/
          @log.mapping.should       == nil
        end

        it "logs message without mappping" do
          Mapping.stub!(:match).and_return @mapping
          @mapping.stub!(:process).and_raise RuntimeError
          @msg = Message.receive(mail(:basic))
          @log = LoggedMail.first
          @log.should_not           == nil
          @log.delivered_at.should  == nil
          @log.error_message.should =~ /RuntimeError/
          @log.mapping.should       == @mapping
        end
      end

      describe "with mapping" do
        before :all do
          @msg = Message.receive(mail(:mapped))
          @log = LoggedMail.first
        end

        it "logs message" do
          @log.should_not == nil
        end

        it "links mapping" do
          @log.mapping.should == @mapping
        end

        it "sets subject" do
          @log.subject.should == @msg.subject
        end

        it "sets recipient" do
          @log.recipient.should == @msg.recipients(@mapping.recipient_header_order).first
        end

        it "sets delivered_at" do
          @log.delivered_at.should_not == nil
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
        @message = Message.parse(@raw)
      end

      it "parses TMail::Mail headers" do
        @message.headers.should == {'mime-version' => '1.0', 'content-type' => 'text/plain; charset=ISO-8859-1', 
          'x-custom' => 'reply', 'content-transfer-encoding' => '7bit', 'content-disposition' => 'inline'}
      end

      it "#parse parses TMail::Mail object from raw text" do
        @message.mail.should be_kind_of(TMail::Mail)
      end

      it "recognizes Delivered-To and To: headers as recipients" do
        @message.recipients.should == %w(processor@astrotrain.com)
      end

      it "recognizes From: header as sender" do
        @message.sender.should == %(Bob <user@example.com>)
      end

      it "recognizes Subject: header" do
        @message.subject.should == 'Fwd: blah blah'
      end

      it "recognizes message body" do
        @message.body.should == @body
      end

      it "retains raw message" do
        @message.raw.should == @raw
      end
    end
    
    describe "iso-8859-1 encoded headers" do
      before :all do
        @raw     = mail("iso-8859-1")
        @message = Message.parse(@raw)
      end
      
      it "recognizes From: header with strange encoding" do
        @message.sender.should == %(Matthéw <user@example.com>)
      end
    end
    
    describe "utf-8 encoded headers" do
      before :all do
        @raw     = mail("utf-8")
        @message = Message.parse(@raw)
      end
      
      it "recognizes From: header with strange encoding" do
        @message.sender.should == %(isnard naiké <user@example.com>)
      end
    end

    describe "multipart message" do
      before :all do
        @raw     = mail(:multipart)
        @message = Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        @message.mail.should be_kind_of(TMail::Mail)
      end

      it "recognizes Delivered-To/To: headers as recipient" do
        @message.recipients.should == %w(foo@example.com)
      end

      it "recognizes message body" do
        @message.body.should == "Testing out rich emails with attachments!\n[state:hold responsible:rick]\n\n"
      end

      it "retrieves attachments" do
        @message.should have(1).attachments
      end

      it "retrieves attachment filename" do
        @message.attachments.first.filename.should == 'bandit.jpg'
      end

      it "retrieves attachment content_type" do
        @message.attachments.first.content_type.should == 'image/jpeg'
      end
    end

    describe "apple multipart message" do
      before :all do
        @raw     = mail(:apple_multipart)
        @message = Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        @message.mail.should be_kind_of(TMail::Mail)
      end

      it "recognizes To: header as recipient" do
        @message.recipients.should == %w(foo@example.com)
      end

      it "recognizes message body" do
        @message.body.should == "Let's have a test here:\r\n\r\n\r\n\nYum\r\n\r\n\r\nOn Feb 10, 2009, at 3:37 PM, Tender Support wrote:\r\n\r\n> // Add your reply above here\r\n> ==================================================\r\n> From: Tyler Durden\r\n> Subject: Email attachments and file upload\r\n>\r\n> not at the moment ... let me test\r\n>\r\n> View this Discussion online: http://foobar.com\r\n> .\r\n\r\n\r\n\r\n\r\n--Apple-Mail-7-451386929--"
      end

      it "retrieves attachments" do
        @message.should have(1).attachments
      end

      it "retrieves attachment filename" do
        @message.attachments.first.filename.should == 'logo.gif'
      end

      it "retrieves attachment content_type" do
        @message.attachments.first.content_type.should == 'image/gif'
      end
    end

    describe "multiple sender/recipients" do
      before :all do
        @raw     = mail(:multiple)
        @message = Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        @message.mail.should be_kind_of(TMail::Mail)
      end

      it "recognizes To: headers as recipients" do
        @message.recipients.should == %w(processor@astrotrain.com other@example.com)
      end

      it "recognizes To: headers as recipients with custom header order" do
        @message.recipients(%w(to original_to delivered_to)).should == %w(other@example.com processor@astrotrain.com)
      end

      it "recognizes From: header as sender" do
        @message.sender.should == %(user@example.com, boss@example.com)
      end

      it "recognizes Subject: header" do
        @message.subject.should == 'Fwd: blah blah'
      end

      it "recognizes message body" do
        @message.body.should == @body
      end

      it "retains raw message" do
        @message.raw.should == @raw
      end
    end

    describe "recipients in the body" do
      before :all do
        @raw     = mail(:multiple_with_body_recipients)
        @message = Message.parse(@raw)
      end

      it "recognizes in-body emails and To: headers as recipients" do
        @message.recipients.should == %w(processor+foobar@astrotrain.com processor+blah@astrotrain.com processor@astrotrain.com other@example.com)
      end
    end

    describe "with x-original-to header" do
      before :all do
        @raw     = mail(:custom)
        @message = Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        @message.mail.should be_kind_of(TMail::Mail)
      end

      it "recognizes X-Original-to: header as recipient" do
        @message.recipients.should == %w(processor-reply-57@custom.com processor-delivered@astrotrain.com processor@astrotrain.com)
      end

      it "recognizes Delivered-To: header as recipient with custom header order" do
        @message.recipients(%w(delivered_to original_to to)).should == %w(processor-delivered@astrotrain.com processor-reply-57@custom.com processor@astrotrain.com)
      end

      it "recognizes To: header as recipient with custom header order" do
        @message.recipients(%w(to original_to delivered_to)).should == %w(processor@astrotrain.com processor-reply-57@custom.com processor-delivered@astrotrain.com)
      end

      it "recognizes From: header as sender" do
        @message.sender.should == %(user@example.com, boss@example.com)
      end

      it "recognizes Subject: header" do
        @message.subject.should == 'Fwd: blah blah'
      end

      it "recognizes message body" do
        @message.body.should == @body
      end

      it "retains raw message" do
        @message.raw.should == @raw
      end
    end

    describe "with multiple delivered-to headers" do
      before :all do
        @raw     = mail(:multiple_delivered_to)
        @message = Message.parse(@raw)
      end

      it "recognizes Delivered-to: header as recipient" do
        @message.recipients.should == %w(processor-reply-57@custom.com processor-delivered@astrotrain.com processor@astrotrain.com)
      end
    end
  end

  describe "queueing" do
    it "writes contents queue path" do
      filename = Message.queue("boo!")
      IO.read(filename).should == 'boo!'
    end

    before :all do
      Message.queue_path = Merb.root / 'spec' / 'fixtures' / 'queue'
      FileUtils.rm_rf Message.queue_path
      FileUtils.mkdir_p Message.queue_path
    end
  end
end