require File.dirname(__FILE__) + '/../../../init'
require "quick_books_sync"
require 'spec/expectations'
require 'spec/matchers'
require 'spec/mocks'
require 'ap'

require 'quick_books_sync/test/cucumber/quick_books_world'
require 'quick_books_sync/test/mock_qb_repo'


def d(*args)
  puts *args.map {|a| ERB::Util.h(a.inspect) + "<br />"}
end

class QuickBooksSync::StubLogger
  def update(status); end
end

World { QuickBooksSync::Test::Cucumber::QuickBooksWorld.new }
