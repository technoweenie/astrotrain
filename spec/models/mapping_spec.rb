require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Mapping do
  it "defaults #email_domain to Mapping.default_domain" do
    Mapping.new.email_domain.should == Mapping.default_domain
  end

  it "defaults #transport to 'http_post" do
    Mapping.new.transport.should == 'http_post'
  end

  it "knows http_post transport uses urls" do
    Mapping.new(:transport => 'http_post').destination_uses_url?.should == true
  end

  it "knows jabber transport uses emails" do
    Mapping.new(:transport => 'jabber').destination_uses_email?.should == true
  end

  describe "matching" do
    before :all do
      User.transaction do
        User.all.destroy!
        Mapping.all.destroy!
        @user     = User.create!(:login => 'user')
        @mapping1 = @user.mappings.create!(:email_user => '*')
        @mapping2 = @user.mappings.create!(:email_user => 'abc*')
        @mapping3 = @user.mappings.create!(:email_user => 'abc')
      end
    end

    it "matches email user" do
      Mapping.match("abc@#{Mapping.default_domain}").should == @mapping3
    end

    it "matches email partial wildcard" do
      Mapping.match("abc1@#{Mapping.default_domain}").should == @mapping2
    end

    it "matches email partial wildcard" do
      Mapping.match("def@#{Mapping.default_domain}").should == @mapping1
    end
  end

  describe "validation" do
    before :all do
      User.transaction do
        User.all.destroy!
        Mapping.all.destroy!
        @user    = User.create!(:login => 'user')
        @mapping = @user.mappings.create!(:email_user => 'xyz')
      end
    end

    %w(abc abc_def abc-123 abc+def abc%def foo* *).each do |valid|
      it "allows #email_user == #{valid.inspect}" do
        valid_mapping(:email_user => valid).should be_valid
      end
    end

    %w(a\ b abc! abc? foo*bar *foo).each do |valid|
      it "rejects #email_user == #{valid.inspect}" do
        valid_mapping(:email_user => valid).should_not be_valid
      end
    end

    %w(abc abc_def abc-123 abc.def).each do |valid|
      it "allows #email_domain == #{valid.inspect}" do
        valid_mapping(:email_domain => valid).should be_valid
      end
    end

    %w(a\ b abc! abc? abc+def abc%def).each do |valid|
      it "rejects #email_domain == #{valid.inspect}" do
        valid_mapping(:email_domain => valid).should_not be_valid
      end
    end

    %w(http://example.com https://example.com http://example.com/ http://example.com/foo http://example.com/foo/bar.html http://example.com/foo?blah[baz]=1).each do |valid|
      it "allows #destination == #{valid.inspect} for http_post transport" do
        valid_mapping(:destination => valid, :transport => 'http_post').should be_valid
      end
    end

    %w(foo@bar.com).each do |valid|
      it "allows #destination == #{valid.inspect} for jabber transport" do
        valid_mapping(:destination => valid, :transport => 'jabber').should be_valid
      end
    end

    it "rejects duplicate email_user/email_domain" do
      valid_mapping(:email_user => @mapping.email_user).should_not be_valid
    end

    it "accepts unique email_user" do
      valid_mapping.should be_valid
    end

    it "accepts unique email_user + email_domain" do
      valid_mapping(:email_user => @mapping.email_user, :email_domain => 'example.com').should be_valid
    end

  protected
    def valid_mapping(options = {})
      Mapping.new({:user_id => 1, :destination => 'http://foo.com', :email_user => 'sample', :transport => 'http_post'}.update(options))
    end
  end
end