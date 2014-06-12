require File.expand_path(File.dirname(__FILE__) + '/../../init')

require 'rubygems'
require 'bundler'
Bundler.setup

require 'quick_books_sync'
require 'quick_books_sync/ui'

require 'ostruct'

qb = QuickBooksSync::Resource.from_raw(:Customer, {:name => "Steve"}, {:quick_books_id => "abc123"})
remote = QuickBooksSync::Resource.from_raw(:Customer, {:name => "Dave"}, {:quick_books_id => "abc123"})


TEST_CONFLICT = QuickBooksSync::Conflict.new(qb, remote)
TEST_ERROR    = OpenStruct.new(:message => "OH NOES!")

class TestUI < QuickBooksSync::UI
  def do_sync(resolutions)
    10.times do |i|
      update_status "Status message message message message #{i}..."
      sleep 0.2
    end

    if resolutions.empty?
      render_status [TEST_CONFLICT], [TEST_ERROR]
    else
      render_status [], []
    end
  end

  def display_warning_message
    # noop
  end

end

TestUI.start({})
