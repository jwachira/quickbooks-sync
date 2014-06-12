require File.dirname(__FILE__) + '/spec_helper'

describe QuickBooksSync::PennyConverter do
  it "should convert floats" do
    QuickBooksSync::PennyConverter.to_pennies(1.60).should == 160
  end
end