$: << File.expand_path(File.dirname(__FILE__) + '/../lib') 
require 'quick_books_sync'

REPO_FILENAME = "sync.json"
sync_server = QuickBooksSync::Repository::Remote.new(:host => 'localhost', :port => 4567)
local       = QuickBooksSync::Repository::Local.load_from File.open(REPO_FILENAME)

local.sync_to(sync_server)

