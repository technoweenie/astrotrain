require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "UserNotFound", :shared => true do
  before do
    User.stub!(:get).and_return(nil)
  end
  
  it "should raise NotFound" do
    lambda {
      do_request
    }.should raise_error
  end
end

describe Users do
  
  describe "GET index" do
    def do_request
      dispatch_to(Users, :index) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should be successful" do
      do_request.should be_successful
    end
    
    it "should assign users for the view" do
      users = [mock(:user), mock(:user)]
      User.should_receive(:all).and_return(users)
      do_request.assigns(:users).should == users
    end
  end
  
  describe "GET show" do
    before do
      @user = mock(:user)
      @mappings = [mock(:mapping)]
      @user.stub!(:mappings).and_return(@mappings)
      User.stub!(:get).and_return(@user)
    end
    
    def do_request
      dispatch_to(Users, :show, :id => 1) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should be successful" do
      do_request.should be_successful
    end
    
    it "should assign user for the view" do
      User.should_receive(:get).with('1').and_return(@user)
      do_request.assigns(:user).should == @user
    end
  end
  
  describe "GET show (with missing user)" do    
    def do_request
      dispatch_to(Users, :show, :id => 1) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it_should_behave_like 'UserNotFound'
  end
  
  describe "Get new" do
    before do
      @user = mock(:user)
      User.stub!(:new).and_return(@user)
    end
    
    def do_request
      dispatch_to(Users, :new) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should assign user for view" do
      User.should_receive(:new).and_return(@user)
      do_request.assigns(:user).should == @user
    end
    
    it "should be successful" do
      do_request.should be_successful
    end
  end
  
  describe "POST create (with valid user)" do
    before do
      @attrs = {'login' => 'jnunemaker'}
      @user = mock(:user, :save => true)
      User.stub!(:new).and_return(@user)
    end
    
    def do_request
      dispatch_to(Users, :create, :user => @attrs) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should assign new user" do
      User.should_receive(:new).with(@attrs).and_return(@user)
      do_request.assigns(:user).should == @user
    end
    
    it "should save the user" do
      @user.should_receive(:save).and_return(true)
      do_request
    end
    
    it "should redirect" do
      do_request.should redirect_to(url(:users))
    end
  end
  
  describe "POST create (with invalid user)" do
    before do
      @attrs = {'login' => ''}
      @user = mock(:user, :save => false)
      User.stub!(:new).and_return(@user)
    end
    
    def do_request
      dispatch_to(Users, :create, :user => @attrs) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should assign new user" do
      User.should_receive(:new).with(@attrs).and_return(@user)
      do_request.assigns(:user).should == @user
    end
    
    it "should attempt to save the user" do
      @user.should_receive(:save).and_return(false)
      do_request
    end
    
    it "should be successful" do
      do_request.should be_successful
    end
  end
  
  describe "GET edit" do
    before do
      @user = mock(:user)
      @mappings = [mock(:mapping)]
      @user.stub!(:mappings).and_return(@mappings)
      User.stub!(:get).and_return(@user)
    end
    
    def do_request
      dispatch_to(Users, :edit, :id => 1) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should be successful" do
      do_request.should be_successful
    end
    
    it "should assign user for the view" do
      User.should_receive(:get).with('1').and_return(@user)
      do_request.assigns(:user).should == @user
    end
  end
  
  describe "GET edit (with missing user)" do    
    def do_request
      dispatch_to(Users, :edit, :id => 1) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it_should_behave_like 'UserNotFound'
  end
  
  describe "PUT update (with valid user)" do
    before do
      @attrs = {'login' => 'jnunemaker'}
      @user = mock(:user, :update_attributes => true)
      User.stub!(:get).and_return(@user)
    end
    
    def do_request
      dispatch_to(Users, :update, :id => 1, :user => @attrs) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should assign user" do
      User.should_receive(:get).with('1').and_return(@user)
      do_request.assigns(:user).should == @user
    end
    
    it "should update the user's attributes" do
      @user.should_receive(:update_attributes).and_return(true)
      do_request
    end
    
    it "should redirect" do
      do_request.should redirect_to(url(:users))
    end
  end
  
  describe "PUT update (with invalid user)" do
    before do
      @attrs = {'login' => ''}
      @user = mock(:user, :update_attributes => false)
      User.stub!(:get).and_return(@user)
    end
    
    def do_request
      dispatch_to(Users, :update, :id => 1, :user => @attrs) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should assign new user" do
      User.should_receive(:get).with('1').and_return(@user)
      do_request.assigns(:user).should == @user
    end
    
    it "should attempt to update the user's attributes" do
      @user.should_receive(:update_attributes).and_return(false)
      do_request
    end
    
    it "should be successful" do
      do_request.should be_successful
    end
  end

  describe "PUT update (with missing user)" do    
    def do_request
      dispatch_to(Users, :update, :id => 1) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end

    it_should_behave_like 'UserNotFound'
  end
  
  describe "DELETE destroy" do
    before do
      @user = mock(:users, :destroy => true)
      User.stub!(:get).and_return(@user)
    end
    
    def do_request
      dispatch_to(Users, :destroy, :id => 1) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end
    
    it "should find the user" do
      User.should_receive(:get).with('1').and_return(@user)
      do_request
    end
    
    it "should destroy the user" do
      @user.should_receive(:destroy).and_return(true)
      do_request
    end
    
    it "should redirect" do
      do_request.should redirect_to(url(:users))
    end
  end

  describe "DELETE destroy (with missing user)" do    
    def do_request
      dispatch_to(Users, :destroy, :id => 1) do |controller|
        controller.stub!(:ensure_authenticated)
        controller.stub!(:ensure_admin)
        controller.stub!(:render)
      end
    end

    it_should_behave_like 'UserNotFound'
  end
end