require File.expand_path(File.dirname(__FILE__) + '/../../init')

require 'rubygems'
require 'bundler'
Bundler.setup

require 'quick_books_sync'

def resource(type, data, metadata={})
  QuickBooksSync::Resource.from_raw type, data, metadata
end

def complex_resource_set
  customer = resource("Customer", {"name" => "Bob"}, {:quick_books_id => "abc123"})
  item = resource("ItemService", {"name" => "Awesome"})
  invoice_line = resource("InvoiceLine", {"quantity" => "5", "item" => item})
  invoice = resource("Invoice", {"customer" => customer, :invoice_lines => [invoice_line]}, {:quick_books_id => "xyz987"})

  QuickBooksSync::ResourceSet.new([customer, invoice, item])
end

resources = complex_resource_set

qb = QuickBooksSync::Repository::QuickBooks.new

qb.add resources

# p qb.resources