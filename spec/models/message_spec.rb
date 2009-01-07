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

        it "sets filename" do
          @log.filename.should_not == nil
        end

        it "sets subject" do
          @log.subject.should == @msg.subject
        end

        it "sets recipient" do
          @log.recipient.should == @msg.recipient(@mapping.recipient_header_order)
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

      it "#parse parses TMail::Mail object from raw text" do
        @message.mail.should be_kind_of(TMail::Mail)
      end

      it "recognizes To: header as recipient" do
        @message.recipient.should == %("Processor" <processor@astrotrain.com>)
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

    describe "multipart message" do
      before :all do
        @raw     = mail(:multipart)
        @message = Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        @message.mail.should be_kind_of(TMail::Mail)
      end

      it "recognizes To: header as recipient" do
        @message.recipient.should == %(foo@example.com)
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

    describe "multiple sender/recipients" do
      before :all do
        @raw     = mail(:multiple)
        @message = Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        @message.mail.should be_kind_of(TMail::Mail)
      end

      it "recognizes To: header as recipient with custom header order" do
        @message.recipient(%w(to original_to delivered_to)).should == 'other@example.com, processor@astrotrain.com'
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

    describe "with x-original-to header" do
      before :all do
        @raw     = mail(:custom)
        @message = Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        @message.mail.should be_kind_of(TMail::Mail)
      end

      it "recognizes X-Original-to: header as recipient" do
        @message.recipient.should == 'processor-reply-57@custom.com'
      end

      it "recognizes Delivered-To: header as recipient with custom header order" do
        @message.recipient(%w(delivered_to original_to to)).should == 'processor-delivered@astrotrain.com'
      end

      it "recognizes To: header as recipient with custom header order" do
        @message.recipient(%w(to original_to delivered_to)).should == 'processor@astrotrain.com'
      end

      it "recognizes Delivered-to: header as recipient" do
        @message.recipient.should == 'processor-reply-57@custom.com'
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