require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Message do
  describe "(basic, single sender/recipient)" do
    before :all do
      @message = Message.parse(mail(:basic))
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
  end

  describe "(multiple senders/recipients)" do
    before :all do
      @message = Message.parse(mail(:multiple))
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
  end

  describe "(with x-original-to header)" do
    before :all do
      @message = Message.parse(mail(:original_to))
    end

    it "#parse parses TMail::Mail object from raw text" do
      @message.mail.should be_kind_of(TMail::Mail)
    end

    it "recognizes Delivered-to: header as recipient" do
      @message.recipient.should == 'processor-reply-57@astrotrain.com'
    end

    it "recognizes From: header as senders" do
      @message.senders.should == %w(user@example.com boss@example.com)
    end
  end
end