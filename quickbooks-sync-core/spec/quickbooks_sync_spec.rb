require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "when syncing to an actual QuickBooks repository" do

  include XmlMatchers
  include QuickBooksXmlFragments

  Resource = QuickBooksSync::Resource

  before :each do
    @connection = qb_connection :correct_for_daylight_savings_time? => false

    @quick_books = QuickBooksSync::Repository::QuickBooks.with_connection(@connection)
  end

  context "when adding a collection of resources to QuickBooks" do

    describe "that have many attributes" do
      before do
        @customer = resource('Customer', {'phone' => '123-123-1234', 'name' => 'Steve Dave'})
      end

      it "should add those in the correct order" do
        @connection.
          should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><CustomerAddRq requestID=\"0\"><CustomerAdd><Name>Steve Dave</Name><Phone>123-123-1234</Phone></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>").
          and_return_response(valid_customer_add_response)
        do_add
      end
    end

    before :each do
      @customer = resource('Customer', { :name => 'Steve Dave' }, {:local_id => 1138})
      @connection.stub!(:request => valid_customer_add_response)
    end

    def do_add
      @quick_books.add([ @customer ])
    end

    it "should forward an appropriately formatted XML request to the connection" do
      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><CustomerAddRq requestID=\"0\"><CustomerAdd><Name>Steve Dave</Name></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>").
        and_return_response(valid_customer_add_response)

      do_add
    end

    it "should return a hash of the temporarily mapped IDs to the newly-created metadata" do
      response = do_add
      response.keys.should == [ [:Customer, 1138] ]
      response.values.first.metadata.should  == {
        :quick_books_id => "800000D5-1271699206",
        :created_at => Time.at(1271702806),
        :updated_at => Time.at(1271702806),
        :vector_clock => "1271699206"
      }
    end

    describe "QuickBooks resources" do
      it "should expire the memoization on the resource set after committing an add operation" do
        @connection.stub!(:request => valid_empty_customer_query_response)
        @quick_books.resources.size.should == 0

        @connection.stub!(:request => valid_customer_add_response)
        do_add

        @connection.stub!(:request => valid_customer_query_response)
        @quick_books.resources.size.should == 1
      end
    end
  end

  context "when adding a payment that depends on a transaction" do
    before do
      resources = payment_dependent_on_invoice

      @customer, @invoice, @payment_method, @applied_to_txn, @payment_add =
        [:customer, :invoice, :payment_method, :applied_to_txn, :payment_add].map {|k| resources[k] }
    end

    it "should add the invoice first, then the payment" do
      @connection.should_receive_request(
        "<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><InvoiceAddRq requestID=\"0\"><InvoiceAdd><CustomerRef><ListID>abc123</ListID></CustomerRef></InvoiceAdd></InvoiceAddRq></QBXMLMsgsRq></QBXML>"
      ).and_return_response(valid_invoice_add_response)

      @connection.should_receive_request(valid_payment_add_request).and_return_response(valid_payment_add_response)
      @quick_books.add([@invoice, @payment_add])
    end
  end

  context "when adding a collection of resources with references to each other to Quickbooks (none previously added)" do
    before do
      @customer = resource('Customer', {'name' => 'Steve Dave'})
      @invoice = resource('Invoice', {'customer' => @customer})
    end

    it "should add the customer, then add the dependent invoice" do
      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><CustomerAddRq requestID=\"0\"><CustomerAdd><Name>Steve Dave</Name></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>").
        and_return_response(valid_customer_add_response)

      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><InvoiceAddRq requestID=\"0\"><InvoiceAdd><CustomerRef><ListID>800000D5-1271699206</ListID></CustomerRef></InvoiceAdd></InvoiceAddRq></QBXMLMsgsRq></QBXML>").
        and_return_response(valid_invoice_add_response)

      @quick_books.add([@customer, @invoice])
    end
  end

  context "when adding resources with multiple references to non-added resources" do
    before do
      set = complex_resource_set_by_type(false)

      @customer, @invoice, @item = [:Customer, :Invoice, :Item].map {|k| set[k] }
    end

    it "should add the customer, the item, then the invoice" do
      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><CustomerAddRq requestID=\"0\"><CustomerAdd><Name>Bob</Name></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>").
        and_return_response(valid_customer_add_response)

      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\">
        <InvoiceAddRq requestID=\"0\">
           <InvoiceAdd>
            <CustomerRef><ListID>800000D5-1271699206</ListID></CustomerRef>
            <InvoiceLineAdd>
              <ItemRef><ListID>foobar</ListID></ItemRef>
              <Quantity>5</Quantity>
              <Rate>500</Rate>
            </InvoiceLineAdd>
           </InvoiceAdd>
        </InvoiceAddRq></QBXMLMsgsRq></QBXML>").
        and_return_response(valid_invoice_add_response)

      @quick_books.add([@customer, @invoice])
    end
  end

  context "when adding resources with multiple references to non-added resources, and the ones not yet added have error responses" do
    before do
      set = complex_resource_set_by_type(false)

      @customer, @invoice, @item = [:Customer, :Invoice, :Item].map {|k| set[k] }
    end

    it "should attempt to add the customer, the item, then the invoice" do
      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><CustomerAddRq requestID=\"0\"><CustomerAdd><Name>Bob</Name></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>").
        and_return_response(customer_add_error_response)

      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\">
        <InvoiceAddRq requestID=\"0\">
           <InvoiceAdd>
            <CustomerRef><ListID/></CustomerRef>
            <InvoiceLineAdd>
              <ItemRef><ListID>foobar</ListID></ItemRef>
              <Quantity>5</Quantity>
              <Rate>500</Rate>
            </InvoiceLineAdd>
           </InvoiceAdd>
        </InvoiceAddRq></QBXMLMsgsRq></QBXML>").
        and_return_response(valid_invoice_add_response)

      @quick_books.add([@customer, @invoice])
    end
  end

  context "when adding resources with a reference to already added resources" do
    before do
      @customer = resource('Customer', {'name' => 'Steve Dave'}, {:quick_books_id => "abc123"})
      @invoice = resource('Invoice', {'customer' => @customer})
    end

    it "should add the dependent invoice referencing the existing resources" do
       @connection.
          should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><InvoiceAddRq requestID=\"0\"><InvoiceAdd><CustomerRef><ListID>abc123</ListID></CustomerRef></InvoiceAdd></InvoiceAddRq></QBXMLMsgsRq></QBXML>").
          and_return_response(valid_customer_add_response)

      @quick_books.add([@invoice])
    end
  end

  context "when adding multiple resources, each with a reference to the same unadded resource" do
    before do
      @customer = resource('Customer', {'name' => 'Steve Dave'})
      @invoice1 = resource('Invoice', {'customer' => @customer})
      @invoice2 = resource('Invoice', {'customer' => @customer})
    end

    it "should add the customer (only once), then the invoices" do
      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><CustomerAddRq requestID=\"0\"><CustomerAdd><Name>Steve Dave</Name></CustomerAdd></CustomerAddRq></QBXMLMsgsRq></QBXML>").
        and_return_response(valid_customer_add_response)

      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><InvoiceAddRq requestID=\"0\"><InvoiceAdd><CustomerRef><ListID>800000D5-1271699206</ListID></CustomerRef></InvoiceAdd></InvoiceAddRq><InvoiceAddRq requestID=\"1\"><InvoiceAdd><CustomerRef><ListID>800000D5-1271699206</ListID></CustomerRef></InvoiceAdd></InvoiceAddRq></QBXMLMsgsRq></QBXML>").
        and_return_response(valid_double_invoice_add_response)
      @quick_books.add([@invoice1, @invoice2, @customer])
    end
  end

  describe "when adding an empty list" do
    it "should do nothing" do
      @connection.should_not_receive(:request)
      @quick_books.add([])
    end
  end

  context "when updating existing records in quickbooks" do
    before do
      @customer = resource "Customer",
        {"phone" => "123-123-1234", "name" => "Spam Eggs"},
        {:quick_books_id =>"800000D6-1271805311", :vector_clock => "1271807001"}
    end

    it "should send a valid update request to quickbooks" do
      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><CustomerModRq requestID=\"0\"><CustomerMod><ListID>800000D6-1271805311</ListID><EditSequence>1271807001</EditSequence><Name>Spam Eggs</Name><Phone>123-123-1234</Phone></CustomerMod></CustomerModRq></QBXMLMsgsRq></QBXML>"
      ).
      and_return_response(valid_customer_update_response)

      @quick_books.update([@customer])
    end

    it "should return update vector clocks" do
      @connection.should_receive(:request).and_return(valid_customer_update_response)
      response = @quick_books.update([@customer])
      response.keys.should == [
        [:Customer, "800000D6-1271805311"]
      ]

      response.values.first.metadata.should == {
        :created_at => Time.at(1236892864),
        :updated_at => Time.at(1236892864),
        :vector_clock => "1271811519",
        :quick_books_id => "800000D6-1271805311"
      }
    end
  end

  describe "when deleting records" do
    it "should send a valid delete request to quickbooks" do
      @connection.
        should_receive_request("<QBXML><QBXMLMsgsRq onError=\"continueOnError\"><ListDelRq requestID=\"0\"><ListDelType>Customer</ListDelType><ListID>5</ListID></ListDelRq></QBXMLMsgsRq></QBXML>").
        and_return_response(valid_customer_delete_response)

      @quick_books.delete [["Customer", "5"]]
    end

    it "should do nothing if no ids are passed in" do
      @connection.should_not_receive(:request)
      @quick_books.delete []
    end
  end

  context "when querying existing customers in quickbooks" do

    context "and an error is thrown" do
      before do
        @connection.
          should_receive_request(valid_query_request).
          and_return_response(error_customer_query_response)
      end

      it "should raise an error" do
        lambda {
          @quick_books.resources
        }.should raise_error(QuickBooksSync::QuickBooksException)
      end
    end

    context "and there is no error" do
      before do
        @resources = @connection.stub! :request => valid_customer_query_response
      end
      it "should send valid XML" do
        @connection.
          should_receive_request(valid_query_request).
          and_return_response(valid_customer_query_response)

        @quick_books.resources
      end

      describe "when daylight savings time is occuring" do
        before do
          @connection.stub! :correct_for_daylight_savings_time? => true
        end
        subject {@quick_books.resources.first}

        it "should correct for QuickBooks' stupid fuckup where the time is wrong.  fuck you quickbooks" do
          # 1236889307 = 1236892907 - ( 60 * 60 )
          subject.last_modified.should == Time.at(1236889307)
        end
      end

      describe "resources returned" do
        subject {@quick_books.resources}

        it "should have only one resource" do
          subject.length.should == 1
        end
      end

      describe "the first resource" do
        subject { @quick_books.resources.first }

        it { should be_a(QuickBooksSync::Resource) }
        it { should be_a(QuickBooksSync::Resource::Customer) }

        it "should be a customer" do
          subject.type.should == :Customer
        end

        it "should have the correct name" do
          subject[:name].should == "Builder's Supply LLC"
        end

        it "should have the correct timestamp" do
          subject.last_modified.should == Time.at(1236892907)
        end

        it "should have the correct ID" do
          subject.id.should == [:Customer, "40000-1236889264"]
        end

        it "should have the correct vector clock" do
          subject.vector_clock.should == "1236889307"
        end

      end
    end
  end

  describe "syncing invoices and customers" do
    before do
      @connection.
        should_receive_request(valid_query_request).
        and_return_response(valid_query_response)

      @customer = @quick_books.resources.detect {|t| t.type == :Customer}
      @invoice = @quick_books.resources.detect {|t| t.type == :Invoice}
      @item = @quick_books.resources.detect {|t| t.is_a?(Resource::Item) }
    end

    it "should load both resources" do
      @quick_books.resources.map(&:type).sort_by(&:to_s).should == [:Customer, :Invoice, :ItemService]
    end

    describe "the invoice" do
      before do
        @local_customer = resource "Customer", {"first_name" => "Harold", "last_name" => "Q3"}, {:quick_books_id => "8000000E-1273520333"}
        @local_item_service = resource "ItemService", {"name" => "Awesome"}, {:quick_books_id => "80000002-1273542783"}
        @local_invoice_line = resource "InvoiceLine", {"quantity" => "1", "rate" => "10.00", "item" => @local_item_service}
        @local_invoice = resource "Invoice", {"invoice_lines" => [@local_invoice_line], "customer" => @local_customer}, {:quick_books_id => "7-1274221220"}
      end

      it "should be == to another, local invoice" do
        @invoice.should == @local_invoice
      end
    end

    describe "the invoice line" do
      before do
        @invoice_line = @invoice['invoice_lines'].first
      end

      it "should have a nil id" do
        @invoice_line.id.should == [:InvoiceLine, nil]
      end

      it "should have the correct quantity" do
        @invoice_line["quantity"].should == "1"
      end
    end


    describe "serialized" do
      it "should serialize all fields correctly" do
        @customer.serialized.should == [:Customer,
         {:name=>"Harold R2",
          :job_status=>"None",
          :is_active=>"true",
          :last_name=>"Q3",
          :first_name=>"Harold"
         },
         {:updated_at=>1274224820,
          :vector_clock=>"1273799447",
          :quick_books_id=>"8000000E-1273520333",
          :created_at=>1273523933}]
      end

      it "should properly serialize to JSON, including nested resources" do
        @quick_books.resources.to_json.should be_json([["Customer",
          {"name"=>"Harold R2",
           "job_status"=>"None",
           "is_active"=>"true",
           "last_name"=>"Q3",
           "first_name"=>"Harold"
          },
          {"created_at"=>1273523933,
           "updated_at"=>1274224820,
           "quick_books_id"=>"8000000E-1273520333",
           "vector_clock"=>"1273799447"}],
         ["Invoice",
          {"invoice_lines"=>[["InvoiceLine", {"quantity"=>"1", "rate" => "10.00", "item" => "80000002-1273542783"}, {}]],
           "customer" => "8000000E-1273520333",
           "balance_remaining" => "10.00"
          },
          {"created_at"=>1274224820,
           "updated_at"=>1274224820,
           "quick_books_id"=>"7-1274221220",
           "vector_clock"=>"1274221220"}],
        ["ItemService",
          {"name"=>"Awesome"},
          {"created_at"=>1273546383,
           "updated_at"=>1273546383,
           "quick_books_id"=>"80000002-1273542783",
           "vector_clock"=>"1273542783"}]
        ]
        )
      end
    end

    describe "the customer" do
      subject { @customer }
      it { should be_an(Resource::Customer) }
    end

    describe "the invoice" do
      subject { @invoice }
      it "should have the correct ID" do
        subject.id.should == [:Invoice, "7-1274221220"]
      end

      it "should have the correct customer" do
        subject[:customer].should == @customer
      end

      it "should have lines" do
        subject[:invoice_lines].length.should == 1
      end

      it "should have the correct balance remaining" do
        subject[:balance_remaining].should == "10.00"
      end

      describe "lines" do

        it "should return the same object when called twice" do
          a = @invoice[:invoice_lines].first
          b = @invoice[:invoice_lines].first

          a.object_id.should == b.object_id
        end

        subject { @lines = @invoice[:invoice_lines].first }
        it "should have correct attributes" do
          subject[:quantity].should == "1"
        end

        it "should have the correct item" do
          subject[:item].should == @item
        end

        it { should be_an(Resource::InvoiceLine) }

      end

    end

  end

  describe "with Items" do
    before do
      @connection.
        should_receive_request(valid_query_request).
        and_return_response(valid_item_query_response)
      @resources = @quick_books.resources
    end


    it "should load them" do
      @resources.length.should == 1
    end

    describe "the ItemService" do
      subject { @resources.first }
      it "should be an ItemService" do
        subject.type.should == :ItemService
      end

      it "should have the proper ID" do
        subject.id.should == [:Item, "80000002-1273542783"]
      end
      it { should be_valid }

      it "should be awesome" do
        subject["name"].should == "Awesome"
      end
    end

    it "should return the ItemService when queried for an Item" do
      @resources.by_id[[:Item, "80000002-1273542783"]].should == @resources.first
    end

  end

  describe "with ReceivePayments" do

    before :each do
      @payment_method = resource('PaymentMethod', {'name' => "Chickens"}, {:quick_books_id => "foo999"})
      set = complex_resource_set_by_type()

      @customer, @invoice, @item = [:Customer, :Invoice, :Item].map {|k| set[k] }

      @applied_to_txn = resource('AppliedToTxn', { 'invoice' => @invoice, 'payment_amount' => '123.45' })
      @payment_add = resource('ReceivePayment',
        'customer'        => @customer,
        'applied_to_txns'  => [ @applied_to_txn ],
        'payment_method' => @payment_method)
    end

    it "should add them using proper XML" do
      @connection.
        should_receive_request(valid_payment_add_request).
        and_return_response(valid_payment_add_response)
      @quick_books.add [@payment_add]
    end
  end

  describe "adding CreditMemos" do
    before do
      @connection.
        should_receive_request(valid_credit_memo_add_request).
        and_return_response(valid_credit_memo_add_response)
    end

    it "should add them using proper XML" do
      set = complex_resource_set_by_type()

      @customer, @item = [:Customer, :ItemService].map {|k| set[k] }

      @credit_memo_line = resource :CreditMemoLine, {:item => @item, :quantity => "1", :rate => "50.00"}
      @credit_memo = resource :CreditMemo, {:credit_memo_lines => [@credit_memo_line], :customer => @customer}, {:local_id => "43"}

      response = @quick_books.add([@credit_memo])
      response.keys.should == [[:CreditMemo, "43"]]
      response.values.first.metadata.should == {
        :quick_books_id=>"91-1283386643",
        :created_at=>Time.at(1283390243),
        :updated_at=>Time.at(1283390243),
        :vector_clock=>"1283386643"
      }
    end
  end


  context "paginated results" do
    it "should keep querying until there are none left" do
      @connection.
        should_receive_request(valid_query_request).
        and_return_response(valid_first_page_response)

      @connection.
        should_receive_request(valid_second_page_request).
        and_return_response(valid_last_page_response)

      @resources = @quick_books.resources
      @resources.map(&:type).sort_by(&:to_s).should == [:Customer, :Customer, :Invoice]

    end
  end

  describe "reporting on resource metadata" do

    context "when adding a resource" do

      before :each do
        @customer = resource('Customer', { :name => 'Steve Dave' }, {:local_id => '1138'})
      end

      def do_add
        @quick_books.add([ @customer ])
      end

      subject { do_add[@customer.id] }

      context "when an operation is successful" do

        before :each do
          @connection.stub!(:request => valid_customer_add_response)
        end

        it { should_not be_error }

        it "should have associated metadata" do
          subject.metadata.should == {
            :quick_books_id => "800000D5-1271699206",
            :created_at => Time.at(1271702806),
            :updated_at => Time.at(1271702806),
            :vector_clock => "1271699206"
          }
        end
      end

      context "when operation has error" do

        before :each do
          @connection.stub!(:request => customer_add_error_response )
        end

        it { should be_error }

      end

      context "when operation has several errors" do

        def do_add
          @quick_books.add((0..33).map {|i| resource('Customer', { :name => 'Steve Dave' }, {:local_id => i.to_s})})
        end

        before :each do
          @connection.stub!(:request => batch_customer_add_error_response )
        end

        it "should have an error for each" do
          response = do_add
          response.size.should == 16
          response.each {|k,v| v.should be_error}
        end
      end


    end

    context "when updating a resource" do

      before :each do
        @customer = resource('Customer', { :name => 'Steve Dave' }, {:quick_books_id => '1138'})
      end

      def do_update
        @quick_books.update([ @customer ])
      end

      subject { do_update[@customer.id] }

      context "when an operation is successful" do

        before :each do
          @connection.stub!(:request => valid_customer_update_response)
        end

        it { should_not be_error }

        it "should have associated metadata" do
          subject.metadata.should == {
            :quick_books_id => "800000D6-1271805311",
            :created_at => Time.at(1236892864),
            :updated_at => Time.at(1236892864),
            :vector_clock => "1271811519"
          }
        end
      end

      context "when operation has error" do

        before :each do
          @connection.stub!(:request => customer_update_error_response )
        end

        it { should be_error }

        it "should not have a resource" do
          subject.resource.should be_nil
        end

      end

    end
  end

end
