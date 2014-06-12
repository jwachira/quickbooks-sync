require 'logger'

module QuickBooksSync
  FileUtils.mkdir_p("log")
  LOG = Logger.new("log/quickbooks.log")
end
