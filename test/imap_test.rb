require File.join(File.dirname(__FILE__), "test_helper")
require 'astrotrain/imap'

Astrotrain::Imap.connection_class = Astrotrain::Imap::MockConnection

class Astrotrain::ImapTest < Astrotrain::TestCase
  before do
    @imap = Astrotrain::Imap.new('host', :port => 1, :use_ssl => true, :user => 'ricky', :password => 'bobby')
    @conn = @imap.connection
    @mbox = Astrotrain::Imap::Mailbox.new(@imap, "foo")
  end

  describe "Imap" do
    it "logs into imap server" do
      @imap.connection
      assert_equal [%(login(["ricky", "bobby"]))], @conn.trace
    end

    it "finds mailboxes" do
      mock(@conn).list('', '*') { [OpenStruct.new(:name => 'foo'), OpenStruct.new(:name => 'bar')] }
      assert_equal [Astrotrain::Imap::Mailbox.new(@imap, 'foo'), Astrotrain::Imap::Mailbox.new(@imap, 'bar')],
        @imap.mailboxes
    end

    it "opens connection" do
      assert !@imap.connection.disconnected?
    end

    it "closes connection" do
      @imap.connection.close
      assert @conn.disconnected?
    end
  end

  describe "Imap::Mailbox" do
    it "performs operations inside the mailbox" do
      @mbox.with { 1 + 1 }
      assert_equal %(select([#{@mbox.name.inspect}])), @conn.trace.last
    end
  
    it "searches mailbox" do
      mock(@conn).search(["foo", "bar"])    { [2, 1] }
      mock(@conn).fetch([2, 1], %w(RFC822)) { [OpenStruct.new(:seqno => 2, :attr => {}), OpenStruct.new(:seqno => 1, :attr => {})] }
      assert_equal [Astrotrain::Imap::Message.new(OpenStruct.new(:seqno => 2, :attr => {})), Astrotrain::Imap::Message.new(OpenStruct.new(:seqno => 1, :attr => {}))],
        @mbox.search("foo bar")
    end
  
    it "destroys mailbox" do
      @mbox.destroy
      assert_equal %(delete([#{@mbox.name.inspect}])), @conn.trace.last
    end
  
    it "moves given message ids" do
      @other = Astrotrain::Imap::Mailbox.new(@imap, "bar")
      @mbox.move [1, 2], @other
      assert_equal %(store([[1, 2], "+FLAGS", [:Deleted]])), @conn.trace.pop
      assert_equal %(copy([[1, 2], "bar"])),                 @conn.trace.pop
    end
  
    it "moves given messages" do
      @other = Astrotrain::Imap::Mailbox.new(@imap, "bar")
      @mbox.move [OpenStruct.new(:number => 1), OpenStruct.new(:number => 2)], @other
      assert_equal %(store([[1, 2], "+FLAGS", [:Deleted]])), @conn.trace.pop
      assert_equal %(copy([[1, 2], "bar"])),                 @conn.trace.pop
    end
  
    it "destroys given message_ids" do
      @mbox.destroy_messages [1, 2]
      assert_equal %(store([[1, 2], "+FLAGS", [:Deleted]])), @conn.trace.last
    end
  
    it "destroys given messages" do
      @mbox.destroy_messages [OpenStruct.new(:number => 1), OpenStruct.new(:number => 2)]
      assert_equal %(store([[1, 2], "+FLAGS", [:Deleted]])), @conn.trace.last
    end
  end
end