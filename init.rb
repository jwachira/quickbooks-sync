# let's get everything in the load paths with a minimum of insanity.

["quickbooks-sync-core", "acts_as_quick_books_resource", "quickbooks-sync-ui", "quickbooks-sync-connection"].each do |path|
  complete_path = File.expand_path("#{File.dirname(__FILE__)}/#{path}/lib")
  $: << complete_path unless $:.include?(complete_path)
end