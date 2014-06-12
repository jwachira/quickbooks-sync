$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'quick_books_sync'

repo = QuickBooksSync::Repository::QuickBooks.new

repo.resources.each do |resource|
  puts resource.to_json
end
