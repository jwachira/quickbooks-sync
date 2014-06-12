require File.dirname(__FILE__) + '/../spec_helper'

describe QuickBooksSync::ActsAsQuickBooksResource::InvoiceLine do
  InvoiceLine = QuickBooksSync::ActsAsQuickBooksResource::InvoiceLine

  def become_rate(expected)
    simple_matcher("should convert to a string") do |number|
      InvoiceLine.new(:rate_in_cents => number).rate == expected
    end
  end

  def set_rate_in_cents_to(expected)
    simple_matcher("should convert to rate") do |number|
      InvoiceLine.new(:rate => number).rate_in_cents == expected
    end
  end

  describe "#rate" do

    it "should convert rate_in_cents" do
      543.should become_rate("5.43")
    end

    it "should convert rate_in_cents" do
      25.should become_rate("0.25")
    end

    it "should convert rate_in_cents" do
      5.should become_rate("0.05")
    end

  end

  describe "#rate=" do

    it "should convert rate_in_cents" do
      "23.50".should set_rate_in_cents_to(2350)
    end

    it "should convert rate_in_cents" do
      "25".should set_rate_in_cents_to(2500)
    end

    it "should convert rate_in_cents" do
      ".25".should set_rate_in_cents_to(25)
    end

    it "should convert rate_in_cents" do
      25.should set_rate_in_cents_to(2500)
    end

    it "should convert rate_in_cents" do
      "1.60".should set_rate_in_cents_to(160)
    end

    it "should convert rate_in_cents" do
      "1.06".should set_rate_in_cents_to(106)
    end


  end

end