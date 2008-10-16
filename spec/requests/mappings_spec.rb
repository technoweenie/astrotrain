require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

given "a mapping exists" do
  request(resource(:mappings), :method => "POST", 
    :params => { :mapping => {  }})
end

describe "resource(:mappings)" do
  describe "GET" do
    
    before(:each) do
      @response = request(resource(:mappings))
    end
    
    it "responds successfully" do
      @response.should be_successful
    end

    it "contains a list of speakers" do
      pending
      @response.should have_xpath("//ul")
    end
    
  end
  
  describe "GET", :given => "a mapping exists" do
    before(:each) do
      @response = request(resource(:mappings))
    end
    
    it "has a list of mappings" do
      pending
      @response.should have_xpath("//ul/li")
    end
  end
  
  describe "a successful POST" do
    before(:each) do
      @response = request(resource(:mappings), :method => "POST", 
        :params => { :mapping => {  }})
    end
    
    it "redirects to resource(:mappings)" do
      @response.should redirect_to(resource(Mapping.first), :message => {:notice => "mapping was successfully created"})
    end
    
  end
end

