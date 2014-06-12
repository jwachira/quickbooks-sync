$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'quick_books_sync'

REPO_FILENAME = "sync.json"

local = QuickBooksSync::Repository::Local.load_from File.open(REPO_FILENAME)
qb = QuickBooksSync::Repository::QuickBooks.new

qb.sync_to(local)

local.save_to(File.open(REPO_FILENAME, "w"))
