require File.join(File.dirname(__FILE__), "test_helper")

class Astrotrain::LoggedMailTest < Astrotrain::TestCase
  describe "being created from Message" do
    before :all do
      Astrotrain::Mapping.all.destroy!
      @mapping = Astrotrain::Mapping.create!(:email_user => '*')
      @raw     = mail(:custom)
      @message = Astrotrain::Message.parse(@raw)
      @logged  = Astrotrain::LoggedMail.from(@message, 'foo/bar') do |l|
        l.recipient = @message.recipients(%w(delivered_to)).first
        l.mapping   = @mapping
      end
    end

    it "sets recipient" do
      assert_equal @message.recipients(%w(delivered_to)).first, @logged.recipient
    end

    it "sets mail_file" do
      assert_equal 'foo/bar', @logged.mail_file
    end

    it "sets sender" do
      assert_equal 'user@example.com', @logged.sender
    end

    it "sets subject" do
      assert_equal @message.subject, @logged.subject
    end

    it "sets mapping" do
      assert_equal @mapping, @logged.mapping
    end
  end

  describe "attempted creation with badly encoded message" do
    before :all do
      Astrotrain::Mapping.all.destroy!
      @mapping = Astrotrain::Mapping.create!(:email_user => '*')
      @raw     = mail(:custom)
      @subject = "=?gb2312?B?usO80rXnubrO78341b68urjEsOajrLfJwPvG1tfu0MKxqLzbo6jUsbmkvNuj?= =?gb2312?B?qQ==?="
      @raw.sub! /Subject\: Fwd\: blah blah/, "Subject: #{@subject}"
      @message = Astrotrain::Message.parse(@raw)
      @logged  = Astrotrain::LoggedMail.from(@message) do |l|
        l.recipient = @message.recipients(%w(delivered_to)).first
        l.mapping   = @mapping
      end
    end

    it "sets recipient" do
      assert_equal @message.recipients(%w(delivered_to)).first, @logged.recipient
    end

    it "sets subject" do
      assert_equal @subject, @logged.subject
    end

    it "sets sender" do
      assert_equal 'user@example.com', @logged.sender
    end

    it "sets mapping" do
      assert_equal @mapping, @logged.mapping
    end
  end
end