require File.expand_path(File.dirname(__FILE__) + '/../../init')

require 'rubygems'
require 'bundler'
Bundler.setup


require 'quick_books_sync'
require 'quick_books_sync/connection'

require 'pp'

repo = QuickBooksSync::Repository::QuickBooks.with_connection(QuickBooksSync::Connection.new)

(1...5000).each_slice(1000) do |ids|
  puts ids.first
  customers = ids.map do |id|
    QuickBooksSync::Resource.from_raw("Customer", {"name" => "#{id}-customer-3"}, {})
  end

  repo.add(customers)
end

# repo.resources.each do |resource|
#   puts resource.to_json
# end
