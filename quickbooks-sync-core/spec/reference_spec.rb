require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe QuickBooksSync::Resource, "dealing with references" do
  before do
    @customer = resource("Customer", {"name" => "Bob"})
    @invoice = resource("Invoice", {})
  end

  describe "validity" do
    subject { resource("Invoice", {"customer" => @customer}) }

    it { should be_valid }
  end

  describe "#[]" do
    before do
      @invoice = resource("Invoice", {"customer" => @customer})
    end

    it "should return the customer" do
      @invoice["customer"].should == @customer
    end
  end

end