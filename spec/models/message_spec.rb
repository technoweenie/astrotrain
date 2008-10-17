require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Message do
  describe "mapping" do
    describe "against default domain" do
      before :all do
        User.transaction do
          User.all.destroy!
          Mapping.all.destroy!
          @user     = User.create!(:login => 'user')
          @mapping  = @user.mappings.create!(:email_user => 'xyz')
          @mapping2 = @user.mappings.create!(:email_user => 'xyz',  :email_domain => 'sample.com')
        end
      end

      it "doesn't log message without mapping" do
        lambda { Message.receive(mail(:basic)) }.should_not change(LoggedMail, :count)
      end

      it "logs message with mapping" do
        lambda { Message.receive(mail(:mapped)) }.should change(LoggedMail, :count).by(1)
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
        @message.recipient.should == 'processor@astrotrain.com'
      end

      it "recognizes From: header as senders" do
        @message.senders.should == %w(user@example.com)
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

    describe "multiple senders/recipients" do
      before :all do
        @raw     = mail(:multiple)
        @message = Message.parse(@raw)
      end

      it "#parse parses TMail::Mail object from raw text" do
        @message.mail.should be_kind_of(TMail::Mail)
      end

      it "recognizes Delivered-to: header as recipient" do
        @message.recipient.should == 'processor@astrotrain.com'
      end

      it "recognizes From: header as senders" do
        @message.senders.should == %w(user@example.com boss@example.com)
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

      it "recognizes Delivered-to: header as recipient" do
        @message.recipient.should == 'processor-reply-57@custom.com'
      end

      it "recognizes From: header as senders" do
        @message.senders.should == %w(user@example.com boss@example.com)
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
end