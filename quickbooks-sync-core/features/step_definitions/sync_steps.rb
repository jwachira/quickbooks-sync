
def debug
  puts "==== QuickBooks ===="
  ap @quick_books.resources
  ap @quick_books.resources.first.last_modified
  puts ""
  puts "==== Sync Server ===="
  ap @sync_server.resources
  ap @sync_server.resources.first.last_modified
end

Given /^there is a QuickBooks instance running with no resources$/ do
  @quick_books = QuickBooksSync::Test::MockQBRepo.new []
end

Given /^there is a sync server running with no resources$/ do
  @sync_server = QuickBooksSync::Repository::Local.new []
end

Given /^there is a QuickBooks instance running with the following resources:$/ do |table|
  @quick_books = QuickBooksSync::Test::MockQBRepo.new(
    table.hashes.map {|hash|
      type, attributes, metadata = extract_data(hash)
      QuickBooksSync::Resource.of_type(type).new(attributes, metadata)
  })
end

Given /^there is a sync server running with the following resources:$/ do |table|
  @sync_server = QuickBooksSync::Repository::Local.new(
    table.hashes.map {|hash|
      type, attributes, metadata = extract_data(hash)
      QuickBooksSync::Resource.of_type(type).new(attributes, metadata)
  })
end

Given /^there are no records on the sync server$/ do
  # Noop.
  @sync_server.resources.length.should == 0
end

When /^I synchronize my local QuickBooks data to the sync server$/ do
  @sync_status = QuickBooksSync::Session.sync @quick_books, @sync_server
end

When /^I delete the following record from QuickBooks:$/ do |table|
  table.hashes.each do |hash|
    type, data, metadata = extract_data(hash)
    matches = resource_matches(@quick_books.resources, type, data, metadata)
    @quick_books.delete(matches)
  end
end

Given /^there is a record of type "([^\"]*)" on the sync server with the following attributes:$/ do |type, table|
  attributes = resource_attributes(table.hashes.first)
  metadata = resource_metadata(table.hashes.first)
  resource = QuickBooksSync::Resource.of_type(type).new(attributes, metadata)
  @sync_server.add [ resource ]
end

Given /^there are no records in QuickBooks$/ do
  @quick_books.resources.length.should == 0
end

Then /^QuickBooks should have the following resources:$/ do |table|
  table.hashes.each do |hash|
    type, data, metadata = extract_data(hash)

    matches = resource_matches(@quick_books.resources, type, data, metadata)
    if matches.length != 1
      fail "Actual resources:\n#{@quick_books.resources.inspect}"
    end
  end
end

Then /^the sync server should have the following resources:$/ do |table|
  table.hashes.each do |hash|
    type, data, metadata = extract_data(hash)

    matches = resource_matches(@sync_server.resources, type, data, metadata)
    if matches.length != 1
      fail "Actual resources:\n#{@sync_server.resources.inspect}"
    end
  end
end

Given /^I have changed all the remote resources since syncing them$/ do

  metadata = @sync_server.resources.inject({}) do |_, resource|
    _.merge resource.id => {:changed_since_sync => true}
  end

  @sync_server.update_metadata metadata
end

Then /^there should be (\d+) merge conflicts?$/ do |conflict_count|
  @sync_status.conflicts.size.should == 1
end


