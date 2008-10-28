require File.join( File.dirname(__FILE__), '..', "spec_helper" )

describe User do
  describe "validation" do
    %w(abc abc_def abc-123).each do |valid|
      it "allows #login == #{valid.inspect}" do
        valid_user(:login => valid).should be_valid
      end
    end

    %w(a\ b abc! abc?).each do |valid|
      it "rejects #login == #{valid.inspect}" do
        valid_user(:login => valid).should_not be_valid
      end
    end

    it "requires unique login" do
      begin
        @user = valid_user(:login => 'unique')
        @user.save
        valid_user(:login => 'unique').should_not be_valid
      ensure
        @user.destroy
      end
    end

  protected
    def valid_user(options = {})
      User.new({:login => 'sample', :password => 'monkey', :password_confirmation => 'monkey'}.update(options))
    end
  end
  
  describe "#admin?" do
    before do
      @user = User.new
    end
    
    it "should be true if admin is true" do
      @user.admin = true
      @user.admin?.should be_true
    end
    
    it "should be false if admin is false" do
      @user.admin = false
      @user.admin?.should be_false
    end
  end
  
end