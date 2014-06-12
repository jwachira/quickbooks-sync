require File.expand_path(File.dirname(__FILE__) + '/../../init')

require 'rubygems'
require 'bundler'
Bundler.setup

require 'quick_books_sync'
require 'quick_books_sync/connection'
require 'trollop'

options = Trollop.options do
  opt :file, "filename to load", :type => String
  opt :remote, "remote repo URL", :type => String
end


uri = URI.parse options[:remote]
remote = QuickBooksSync::Repository::Remote.new :host => uri.host,
  :port => uri.port,
  :ssl => uri.scheme == "https"

qb = QuickBooksSync::Repository::QuickBooks.with_connection(QuickBooksSync::Connection.new)
session = QuickBooksSync::Session.sync(qb, remote, [])


# remote.add(qb.resources)

# p session.conflicts