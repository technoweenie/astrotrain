require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe LoggedMail do
  describe "being created from Message" do
    before :all do
      User.all.destroy!
      Mapping.all.destroy!
      @user    = User.create!(:login => 'user')
      @mapping = @user.mappings.create!(:user_id => @user.id, :email_user => '*', :recipient_header_order => 'delivered_to,original_to,to')
      @raw     = mail(:custom)
      @message = Message.parse(@raw)
      @logged  = LoggedMail.from(@message) do |l|
        l.recipient = @message.recipients(%w(delivered_to)).first
        l.mapping   = @mapping
      end
    end

    it "sets recipient" do
      @logged.recipient.should == @message.recipients(%w(delivered_to)).first
    end

    it "sets subject" do
      @logged.subject.should == @message.subject
    end

    it "sets mapping" do
      @logged.mapping.should == @mapping
    end
  end

  describe "attempted creation with badly encoded message" do
    before :all do
      User.all.destroy!
      Mapping.all.destroy!
      @user    = User.create!(:login => 'user')
      @mapping = @user.mappings.create!(:user_id => @user.id, :email_user => '*', :recipient_header_order => 'delivered_to,original_to,to')
      @raw     = mail(:custom)
      @subject = "=?gb2312?B?usO80rXnubrO78341b68urjEsOajrLfJwPvG1tfu0MKxqLzbo6jUsbmkvNuj?= =?gb2312?B?qQ==?="
      @raw.sub! /Subject\: Fwd\: blah blah/, "Subject: #{@subject}"
      @message = Message.parse(@raw)
      @logged  = LoggedMail.from(@message) do |l|
        l.recipient = @message.recipients(%w(delivered_to)).first
        l.mapping   = @mapping
      end
    end

    it "sets recipient" do
      @logged.recipient.should == @message.recipients(%w(delivered_to)).first
    end

    it "sets subject" do
      @logged.subject.should == @subject
    end

    it "sets mapping" do
      @logged.mapping.should == @mapping
    end
  end
end