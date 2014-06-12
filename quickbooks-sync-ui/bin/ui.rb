require File.expand_path(File.dirname(__FILE__) + '/../../init')

require 'rubygems'
require 'bundler'
Bundler.setup

require 'quick_books_sync'
require 'quick_books_sync/ui'
require 'trollop'

options = Trollop.options do
  opt :remote, "remote repo URL", :type => String
end

Trollop.die "Need URL" unless options[:remote]

QuickBooksSync::UI.start options.merge(:version => "9")
