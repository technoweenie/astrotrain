require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe Mapping do
  describe "validation" do
    %w(abc abc_def abc-123 abc+def abc%def).each do |valid|
      it "allows #email_user == #{valid.inspect}" do
        valid_mapping(:email_user => valid).should be_valid
      end
    end

    %w(a\ b abc! abc?).each do |valid|
      it "rejects #email_user == #{valid.inspect}" do
        valid_mapping(:email_user => valid).should_not be_valid
      end
    end

    %w(http://example.com https://example.com http://example.com/ http://example.com/foo http://example.com/foo/bar.html http://example.com/foo?blah[baz]=1).each do |valid|
      it "allows #post_url == #{valid.inspect}" do
        valid_mapping(:post_url => valid).should be_valid
      end
    end

  protected
    def valid_mapping(options = {})
      Mapping.new({:user_id => 1, :post_url => 'http://foo.com', :email_user => 'sample'}.update(options))
    end
  end
end