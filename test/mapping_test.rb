require File.join(File.dirname(__FILE__), "test_helper")

class Astrotrain::MappingTest < Astrotrain::TestCase
  it "defaults #email_domain to Mapping.default_domain" do
    assert_equal Astrotrain::Mapping.default_domain, Astrotrain::Mapping.new.email_domain
  end

  it "defaults #transport to 'http_post" do
    assert_equal 'http_post', Astrotrain::Mapping.new.transport
  end

  it "knows http_post transport uses urls" do
    assert Astrotrain::Mapping.new(:transport => 'http_post').destination_uses_url?
  end

  it "knows jabber transport uses emails" do
    assert Astrotrain::Mapping.new(:transport => 'jabber').destination_uses_email?
  end

  describe "matching" do
    before :all do
      Astrotrain::Mapping.transaction do
        Astrotrain::Mapping.all.destroy!
        @mapping1 = Astrotrain::Mapping.create!(:email_user => '*')
        @mapping2 = Astrotrain::Mapping.create!(:email_user => 'abc*')
        @mapping3 = Astrotrain::Mapping.create!(:email_user => 'abc')
      end
    end

    it "matches email user" do
      assert_equal [@mapping3, "abc@#{Astrotrain::Mapping.default_domain}"], 
        Astrotrain::Mapping.match(["abc@#{Astrotrain::Mapping.default_domain}"])
    end

    it "matches email partial wildcard" do
      assert_equal [@mapping2, "abc1@#{Astrotrain::Mapping.default_domain}"], 
        Astrotrain::Mapping.match(["abc1@#{Astrotrain::Mapping.default_domain}"])
    end

    it "matches email full wildcard" do
      assert_equal [@mapping1, "def@#{Astrotrain::Mapping.default_domain}"],
        Astrotrain::Mapping.match(["def@#{Astrotrain::Mapping.default_domain}"])
    end
  end

  describe "finding reply text" do
    delim = "xyz"

    before :all do
      @mapping = Astrotrain::Mapping.new :separator => delim
    end

    {
      "foo bar\n\n#{delim}\nfoo" => "foo bar", 
      "foo bar\n\nOn 13-Jan-09, at 9:17 AM, ENTP Support wrote:\n\n\n#{delim}\nfoo" => "foo bar", 
      "foo bar\n\nOn Jan 13, 2009 at 2:20 PM, ENTP Support wrote:\n\n\n#{delim}\nfoo" => "foo bar", 
      "foo bar\n\nAm Tuesday 02 December 2008 schrieb Ricky Bobby:\n\n\n#{delim}\nfoo" => "foo bar", 
      "foo bar\n\nLe 18 sept. 08 à 09:08, theRemix a écrit :\n\n\n#{delim}\nfoo" => "foo bar", 
      "foo\n  bar\nbaz\n\n\n> #{delim}" => "foo\n  bar\nbaz",
      "foo\n\nbar\nbaz\n#{delim}" =>  "foo",
      "foo\n  bar\nbaz2\n\n\n\n" => "foo\n  bar\nbaz2",
      ">> #{delim}\n foo bar" => ""
    }.each do |before, after|
      it "parses #{after.inspect} from #{before.inspect}" do
        assert_equal after, @mapping.find_reply_from(before)
      end
    end
  end

  describe "validation" do
    before :all do
      Astrotrain::Mapping.all.destroy!
      @mapping = Astrotrain::Mapping.create!(:email_user => 'xyz')
    end

    %w(abc abc_def abc-123 abc+def abc%def foo* *).each do |valid|
      it "allows #email_user == #{valid.inspect}" do
        assert valid_mapping(:email_user => valid).valid?
      end
    end

    %w(a\ b abc! abc? foo*bar *foo).each do |valid|
      it "rejects #email_user == #{valid.inspect}" do
        assert !valid_mapping(:email_user => valid).valid?
      end
    end

    %w(abc abc_def abc-123 abc.def).each do |valid|
      it "allows #email_domain == #{valid.inspect}" do
        assert valid_mapping(:email_domain => valid).valid?
      end
    end

    %w(a\ b abc! abc? abc+def abc%def).each do |valid|
      it "rejects #email_domain == #{valid.inspect}" do
        assert !valid_mapping(:email_domain => valid).valid?
      end
    end

    %w(http://example.com https://example.com http://example.com/ http://example.com/foo http://rick:monkey@example.com http://example.com:4567/foo http://localhost:3000/foo http://localhost/foo http://example.com/foo/bar.html http://example.com/foo?blah[baz]=1).each do |valid|
      it "allows #destination == #{valid.inspect} for http_post transport" do
        assert valid_mapping(:destination => valid, :transport => 'http_post').valid?
      end
    end

    %w(foo@bar.com).each do |valid|
      it "allows #destination == #{valid.inspect} for jabber transport" do
        assert valid_mapping(:destination => valid, :transport => 'jabber').valid?
      end
    end

    it "rejects duplicate email_user/email_domain" do
      assert !valid_mapping(:email_user => @mapping.email_user).valid?
    end

    it "accepts unique email_user" do
      assert valid_mapping.valid?
    end

    it "accepts unique email_user + email_domain" do
      assert valid_mapping(:email_user => @mapping.email_user, :email_domain => 'example.com').valid?
    end

  protected
    def valid_mapping(options = {})
      Astrotrain::Mapping.new({:destination => 'http://foo.com', :email_user => 'sample', :transport => 'http_post'}.update(options))
    end
  end
end