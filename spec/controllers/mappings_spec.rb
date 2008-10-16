require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe Mappings, "index action" do
  before(:each) do
    dispatch_to(Mappings, :index)
  end
end