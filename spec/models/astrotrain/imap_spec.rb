require File.join( File.dirname(__FILE__), '..', '..', "spec_helper" )
require 'astrotrain/imap'

Astrotrain::Imap.connection_class = Astrotrain::Imap::MockConnection

describe "Astrotrain" do
  before do
    @imap = Astrotrain::Imap.new('host', :port => 1, :use_ssl => true, :user => 'ricky', :password => 'bobby')
    @conn = @imap.connection
    @mbox = Astrotrain::Imap::Mailbox.new(@imap, "foo")
  end

  describe "Imap" do
    it "logs into imap server" do
      @imap.connection
      @conn.trace.should == [%(login(["ricky", "bobby"]))]
    end

    it "finds mailboxes" do
      @conn.mock(:list, '', '*') { [OpenStruct.new(:name => 'foo'), OpenStruct.new(:name => 'bar')] }
      @imap.mailboxes.should == [Astrotrain::Imap::Mailbox.new(@imap, 'foo'), Astrotrain::Imap::Mailbox.new(@imap, 'bar')]
    end

    it "opens connection" do
      @imap.connection.should_not be_disconnected
    end

    it "closes connection" do
      @imap.connection.close
      @conn.should be_disconnected
    end
  end

  describe "Imap::Mailbox" do
    it "performs operations inside the mailbox" do
      @mbox.with { 1.should == 1 }
      @conn.trace.last.should == %(select([#{@mbox.name.inspect}]))
    end

    it "searches mailbox" do
      @conn.mock(:search, ["foo", "bar"])    { [2, 1] }
      @conn.mock(:fetch, [2, 1], %w(RFC822)) { [OpenStruct.new(:seqno => 2, :attr => {}), OpenStruct.new(:seqno => 1, :attr => {})] }
      @mbox.search("foo bar").should == [Astrotrain::Imap::Message.new(OpenStruct.new(:seqno => 2, :attr => {})), Astrotrain::Imap::Message.new(OpenStruct.new(:seqno => 1, :attr => {}))]
    end

    it "destroys mailbox" do
      @mbox.destroy
      @conn.trace.last.should == %(delete([#{@mbox.name.inspect}]))
    end

    it "moves given message ids" do
      @other = Astrotrain::Imap::Mailbox.new(@imap, "bar")
      @mbox.move [1, 2], @other
      @conn.trace.pop.should == %(store([[1, 2], "+FLAGS", [:Deleted]]))
      @conn.trace.pop.should == %(copy([[1, 2], "bar"]))
    end

    it "moves given messages" do
      @other = Astrotrain::Imap::Mailbox.new(@imap, "bar")
      @mbox.move [OpenStruct.new(:number => 1), OpenStruct.new(:number => 2)], @other
      @conn.trace.pop.should == %(store([[1, 2], "+FLAGS", [:Deleted]]))
      @conn.trace.pop.should == %(copy([[1, 2], "bar"]))
    end

    it "destroys given message_ids" do
      @mbox.destroy_messages [1, 2]
      @conn.trace.last.should == %(store([[1, 2], "+FLAGS", [:Deleted]]))
    end

    it "destroys given messages" do
      @mbox.destroy_messages [OpenStruct.new(:number => 1), OpenStruct.new(:number => 2)]
      @conn.trace.last.should == %(store([[1, 2], "+FLAGS", [:Deleted]]))
    end
  end
end