$: << File.expand_path(File.dirname(__FILE__) + '/../lib')
$: << File.expand_path(File.dirname(__FILE__))
require 'quick_books_sync'
require 'quick_books_sync/test_helper'
require 'spec'
require 'spec_helper/quickbooks_xml_fragments'

class Spec::Example::ExampleGroup
  include QuickBooksSync::TestHelper
  extend ResourceSetMatcher

  def qb_connection(options={})
    ValidatingQuickBooksConnection.new options
  end

  before do
    QuickBooksSync::StubLogger.stub(:update => nil)
  end

  def payment_dependent_on_invoice
    customer = resource(:Customer, {:name => 'Steve Dave'}, {:quick_books_id => "abc123"})
    invoice = resource(:Invoice, {:customer => customer, :balance_remaining => "80.00"}, {:local_id => "42"})
    payment_method = resource('PaymentMethod', {:name => "Chickens"}, {:quick_books_id => "foo999"})
    applied_to_txn = resource('AppliedToTxn', { :invoice => invoice, :payment_amount => '123.45' })
    payment_add = resource(:ReceivePayment,
      :customer        => customer,
      :applied_to_txns  => [ applied_to_txn ],
      :payment_method => payment_method)

    {:customer => customer,
     :invoice => invoice,
     :payment_method => payment_method,
     :applied_to_txn => applied_to_txn,
     :payment_add => payment_add}
  end
end

if ENV['TM_MODE'] == 'RSpec'
  require 'erb'

  def d(*args)
    puts *args.map {|a| ERB::Util.h(a.inspect) + "<br />"}
  end
end

require 'rack/test'
