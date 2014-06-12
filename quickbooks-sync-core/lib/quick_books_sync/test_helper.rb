require 'quick_books_sync/test/mock_qb_repo'
require 'quick_books_sync/test/xml_matchers'
require 'quick_books_sync/test/resource_set_matcher'


module QuickBooksSync::TestHelper

  include QuickBooksSync

  def new_local_repo(resources)
    QuickBooksSync::Repository::Local.new resources
  end

  def resource(type, data, metadata={})
    Resource.from_raw type, data, metadata
  end

  def id_or_empty(already_added, id)
    if already_added
      {:quick_books_id => id}
    else
      {}
    end
  end

  def complex_resource_set(already_added=true)
    customer = resource("Customer", {"name" => "Bob"}, id_or_empty(already_added, "abc123"))
    item = resource("ItemService", {"name" => "Awesome"}, id_or_empty(true, "foobar"))
    invoice_line = resource("InvoiceLine", {"quantity" => "5", "item" => item, "rate" => "500"})
    invoice = resource("Invoice", {"customer" => customer, :invoice_lines => [invoice_line]}, id_or_empty(already_added, "xyz987"))
    payment_method = resource("PaymentMethod", {"name" => "Chickens"}, id_or_empty(already_added, "paymentmethod"))
    applied_to_txn = resource("AppliedToTxn", {"invoice" => invoice, "payment_amount" => "60.00"})
    receive_payment = resource("ReceivePayment",
      {"customer" => customer,
       "payment_method" => payment_method,
       "applied_to_txns" => [applied_to_txn]}, id_or_empty(already_added, "rcpmv123"))

    ResourceSet.from_resources([customer, invoice, item, payment_method, receive_payment])
  end

  def complex_resource_set_by_type(already_added = true)
    complex_resource_set(already_added).to_hash_keyed_by(&:type)
  end

  Spec::Matchers.define :be_json do |expected|
    match do |actual|
      JSON.parse(actual) == expected
    end
  end

  class ValidatingQuickBooksConnection

    SCHEMA_FILE = File.expand_path(File.dirname(__FILE__) + "/../../xml/qbxmlops60.xsd")

    def initialize(stubs={})
      stub! stubs
    end

    class XmlExpectation
      include XmlMatchers

      attr_reader :connection, :expected
      def initialize(connection, expected)
        @connection, @expected = connection, expected
      end


      def and_return_response(response)
        connection.should_receive(:request).ordered do |actual|
          actual.class.should == String
          validate(actual)

          actual.should be_xml(expected)
          response
        end
      end

      delegate :validate, :to => :connection
    end


    def should_receive_request(expected)
      XmlExpectation.new(self, expected)
    end

    def self.schema
      @schema ||= begin
        doc = Nokogiri::XML(File.read(SCHEMA_FILE), SCHEMA_FILE)
        Nokogiri::XML::Schema.from_document(doc)
      end
    end

    def validate(xml)
      doc = Nokogiri::XML(xml)

      errors = schema.validate(doc)
      unless errors.empty?
        raise "#{xml.inspect} did not validate: #{errors.inspect}"
      end
    end

    delegate :schema, :to => :"self.class"

  end

end
