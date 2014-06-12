require File.expand_path(File.dirname(__FILE__) + '/../../init')

require 'rubygems'
require 'bundler'
Bundler.setup


require 'quick_books_sync'
require 'quick_books_sync/connection'

require 'pp'

repo = QuickBooksSync::Repository::QuickBooks.with_connection(QuickBooksSync::Connection.new)

p repo.resources.length

# repo.resources.each do |resource|
#   puts resource.to_json
# end
