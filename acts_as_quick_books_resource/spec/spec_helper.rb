begin
  require 'spec'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')

def suppress_stdout(&block)
  stdout = $stdout
  $stdout = File.open('/dev/null', 'w')
  block.call
ensure
  $stdout = stdout
end


require 'quick_books_sync/acts_as_quick_books_resource'
require 'quick_books_sync/acts_as_quick_books_resource/test_models'
require 'quick_books_sync/test_helper'


Spec::Runner.configure do |config|
  config.before { setup_db }
end

def quickbooks_table(name, options={})
  create_table(name, options) do |t|
    yield t
    t.string   "quick_books_id"
    t.boolean "changed_since_sync"
    t.string "vector_clock"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  add_index name, "quick_books_id"
end

def setup_db
  ActiveRecord::Base.establish_connection(
    :adapter  => 'sqlite3',
    :database => ':memory:'
  )

  ActiveRecord::Base.logger = Logger.new(STDERR)
  ActiveRecord::Base.logger.sev_threshold = Logger::WARN

  suppress_stdout do
    ActiveRecord::Schema.define do

      quickbooks_table "items", :force => true do |t|
        t.string "name"
        t.string "type", :required => true
      end

      quickbooks_table "customers", :force => true do |t|
        t.string   "first_name"
        t.string   "last_name"
        t.string   "phone"
        t.string   "full_name"
      end

      add_index "customers", ["first_name", "last_name"], :name => "name_must_be_unique", :unique => true
      add_index "customers", ["full_name"], :name => "index_customers_on_full_name", :unique => true

      quickbooks_table "invoice_lines", :force => true do |t|
        t.integer  "quantity"
        t.string   "description"
        t.integer  "rate_in_cents"
        t.integer  "invoice_id"
        t.integer  "item_id"
      end

      add_index "invoice_lines", ["invoice_id"], :name => "index_invoice_lines_on_invoice_id"

      quickbooks_table "invoices", :force => true do |t|
        t.integer  "customer_id"
        t.date     "due_date"
        t.text     "memo"
      end

      add_index "invoices", ["customer_id"]

      quickbooks_table "payment_methods", :force => true do |t|
        t.text  "name"
      end

      quickbooks_table "receive_payments", :force => true do |t|
        t.integer "customer_id"
        t.integer "payment_method_id"
      end

      add_index :receive_payments, :customer_id

      quickbooks_table "applied_to_txns", :force => true do |t|
        t.integer :receive_payment_id
        t.integer :invoice_id
        t.integer :payment_amount_in_cents
      end

      add_index :applied_to_txns, :receive_payment_id
      add_index :applied_to_txns, :invoice_id

    end

  end
end

class Spec::Example::ExampleGroup
  include QuickBooksSync::TestHelper
end


if ENV['TM_MODE'] == 'RSpec'
  require 'erb'

  def d(*args)
    puts *args.map {|a| ERB::Util.h(a.inspect) + "<br />"}
  end
end
