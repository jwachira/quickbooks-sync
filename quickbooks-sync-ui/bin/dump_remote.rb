require File.expand_path(File.dirname(__FILE__) + '/../../init')

require 'rubygems'
require 'bundler'
Bundler.setup


require 'quick_books_sync'

require 'pp'

repo = QuickBooksSync::Repository::Remote.new :host => "staging.sunnyvale.itu.edu", :port => "43", :ssl => true

repo.resources.each do |resource|
  puts resource.to_json
end
