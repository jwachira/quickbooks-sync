require File.dirname(__FILE__) + '/spec_helper'

describe "#to_packaged" do
  include QuickBooksSync
  ResourceSet = QuickBooksSync::ResourceSet
  Resource = QuickBooksSync::Resource

  subject do
    ResourceSet.from_packaged_string(complex_resource_set.to_packaged)
  end

  it_should_match_the_complex_resource_set
end
