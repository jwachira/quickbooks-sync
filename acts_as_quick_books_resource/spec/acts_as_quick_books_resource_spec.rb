require File.dirname(__FILE__) + '/spec_helper.rb'

module QuickBooksMatchers
  def it_should_be_the_generated_resource
    it "should have identical attributes to the resource" do
      subject["first_name"].should == "Harold"
      subject["last_name"].should == "Donaldson"
    end

    it "should have ActiveRecord the unique id" do
      subject.id.should == [:Customer, Customer.first.id.to_s]
    end

    it "should have no vector clock" do
      subject.vector_clock.should == nil
    end
  end
end

describe QuickBooksSync::ActsAsQuickBooksResource::Repository do

  Customer = QuickBooksSync::ActsAsQuickBooksResource::Customer
  Invoice = QuickBooksSync::ActsAsQuickBooksResource::Invoice
  InvoiceLine = QuickBooksSync::ActsAsQuickBooksResource::InvoiceLine
  Item = QuickBooksSync::ActsAsQuickBooksResource::Item
  ItemService = QuickBooksSync::ActsAsQuickBooksResource::ItemService
  PaymentMethod = QuickBooksSync::ActsAsQuickBooksResource::PaymentMethod
  ReceivePayment = QuickBooksSync::ActsAsQuickBooksResource::ReceivePayment
  AppliedToTxn = QuickBooksSync::ActsAsQuickBooksResource::AppliedToTxn

  Resource = QuickBooksSync::Resource
  ResourceSet = QuickBooksSync::ResourceSet
  before do
    Time.stub! :now => Time.at(1138)
    @repository = QuickBooksSync::ActsAsQuickBooksResource::Repository.new
  end

  describe "syncing a single customer" do
    before do
      Customer.create :first_name => "Harold", :last_name => "Donaldson", :changed_since_sync => true
    end

    describe "using #[] with local id" do
      before do
        @customer = Customer.first
      end

      subject { @repository[[:Customer, @customer.id.to_s]] }

      extend QuickBooksMatchers
      it_should_be_the_generated_resource

      it "should return the Customer record" do
        @customer = Customer.first
        @resource = @repository[[:Customer, @customer.id.to_s]]

        @resource['first_name'].should == "Harold"
      end
    end

    it "should have one resource" do
      @repository.resources.length.should == 1
    end

    describe "the generated Resource" do
      extend QuickBooksMatchers
      it_should_be_the_generated_resource

      subject { @repository.resources.first }

      it { should be_a(Resource) }

      it { should be_changed_since_sync }

      describe "with quickbooks metadata set" do
        before do
          @customer = Customer.first
          @customer.vector_clock = "987654321"
          @customer.quick_books_id = "abc123"
          @customer.save!

          @resource = @repository.resources.first
        end

        describe "using #[] with quickbooks ID" do
          before do
            @resource = @repository[["Customer", "abc123"]]
          end

          it "should return the resource" do
            @resource["first_name"].should == "Harold"
          end
        end

        it "should have the specified id" do
          subject.id.should == [:Customer, "abc123"]
        end

        it "should should have the specified vector clock" do
          subject.vector_clock.should == "987654321"
        end

        it "should have the specified updated_at" do
          subject.updated_at.should == Time.at(1138)
        end

        it "should have the specified created_at" do
          subject.created_at.should == Time.at(1138)
        end

        it "should have the correct metadata" do
          subject.metadata.should == {
            :created_at=>Time.at(1138),
            :vector_clock=>"987654321",
            :local_id=>@customer.id.to_s,
            :quick_books_id=>"abc123",
            :changed_since_sync=>true,
            :updated_at=> Time.at(1138)}
        end

        it "should have the correct to_json" do
          subject.to_json.should be_json(["Customer",
            {
              "name" => "Harold Donaldson",
              "first_name" => "Harold",
              "last_name" => "Donaldson",
            },
            {
              "created_at" => 1138,
              "vector_clock" =>"987654321",
              "local_id" =>@customer.id.to_s,
              "quick_books_id" =>"abc123",
              "changed_since_sync" =>true,
              "updated_at" => 1138
            }])
        end
      end

      describe "#serialized" do
        it "should return the expected result" do
          subject.serialized.should == [:Customer,
            {:name=>"Harold Donaldson", :last_name=>"Donaldson", :first_name=>"Harold"},
            {:updated_at=>subject.updated_at.to_i, :local_id=> Customer.first.id.to_s, :created_at=>subject.created_at.to_i, :changed_since_sync => true}
          ]
        end
      end

    end
  end

  describe "#mark_as_synced" do
    before do
      @customer = Customer.create! :changed_since_sync => true
      @invoice = Invoice.create! :changed_since_sync => true
      @invoice_line = InvoiceLine.create! :changed_since_sync => true

      @repository.mark_as_synced
    end

    it "should mark all resources as synced" do
      [Customer, InvoiceLine, Invoice].each do |klass|
        klass.all.each do |model|
          model.should_not be_changed_since_sync
        end
      end
    end
  end


  describe "adding resources" do
    before do
      @resource = Resource.from_raw "Customer",
        {"first_name" => "Steve", "last_name" => "Dave"},
        {:quick_books_id => "abc123", :vector_clock => "123", :updated_at => Time.at(123)}
    end

    def do_add
      @repository.add [@resource]
    end

    context "when successful" do
      it "should add new ActiveRecord models" do
        do_add
        Customer.count.should == 1
      end

      describe "the new resource" do
        subject { Customer.first }
        it "should have the proper attributes" do
          do_add
          subject.first_name.should == "Steve"
          subject.last_name.should == "Dave"
        end

        it "should not have changed since the last sync" do
          do_add
          subject.should_not be_changed_since_sync
        end

        it "should save the proper vector clock" do
          do_add
          subject.vector_clock.should == "123"
        end

        it "should have the proper quickbooks ID" do
          do_add
          subject.quick_books_id.should == "abc123"
        end

        it "should have the right modified-at date" do
          do_add
          subject.updated_at.should == Time.at(123)
        end
      end
    end

    context "when there is an error" do
      before :each do
        @resource = Resource.from_raw "Customer",
          {"first_name" => "Steve", "last_name" => "Dave", :full_name => "Steve Dave"},
          {:quick_books_id => "abc123", :vector_clock => "123", :updated_at => Time.at(123)}
        @repository.add [@resource]
      end

      def do_add
        @repository.add [@resource]
      end

      it "should have one error" do
        do_add.length.should == 1
      end

      describe "the error" do
        subject { do_add.first }

        it "should notify that the full name is already taken" do
          subject.message.should == "Full name has already been taken"
        end

        it "should include a reference to the QuickBooks resource to whom the error belongs" do
          subject.resource[:last_name].should == "Dave"
        end
      end
    end
  end

  describe "updating resources" do
    before do
      Customer.create! :first_name => "Steve", :last_name => "Dave", :vector_clock => "2", :quick_books_id => "abc123"
      @resource = Resource.from_raw "Customer", {"first_name" => "Harold", "last_name" => "Donaldson"}, {:quick_books_id => "abc123", :vector_clock => "3"}
      @repository.update [@resource]
    end

    it "should not create a new customer" do
      Customer.count.should == 1
    end

    subject { Customer.first }

    it { should_not be_changed_since_sync }

    it "should update an existing Customer data" do
      subject.first_name.should == "Harold"
      subject.last_name.should == "Donaldson"
    end

    it "should update the existing customer vector clock" do
      subject.vector_clock.should == "3"
    end

    it "should not change the id" do
      subject.quick_books_id.should == "abc123"
    end
  end

  describe "updating metadata" do

    describe "with only a local id" do
      before do
        @customer = Customer.create! :first_name => "Harold", :last_name => "Donaldson", :vector_clock => "2", :created_at => Time.at(1138)
        @repository.update_metadata ["Customer", @customer.id.to_s] => {"quick_books_id" => "xyz987"}
        @customer.reload
      end

      it "should update the local id" do
        @customer.quick_books_id.should == "xyz987"
      end

      it "should not nil out created_at" do
        @customer.created_at.should == Time.at(1138)
      end
    end
    before do
      Customer.create! :first_name => "Steve", :last_name => "Dave", :vector_clock => "2", :quick_books_id => "abc123"
      @repository.update_metadata ["Customer", "abc123"] => {"vector_clock" => "3", "updated_at" => Time.at(1234)}
    end

    subject { Customer.first }

    it { should_not be_changed_since_sync }

    it "should change the vector clock" do
      subject.vector_clock.should == "3"
    end

    it "should change updated_at " do
      subject.updated_at.should == Time.at(1234)
    end

    it "should not change the quick_books_id" do
      subject.quick_books_id.should == "abc123"
    end
  end

  describe "updating the activerecord model" do
    before do
      Time.stub! :now => Time.at(5)
      @customer = Customer.create! :first_name => "Bob", :last_name => "Dobalina"
    end

    it "should set created_at on create" do
      @customer.created_at.should == Time.at(5)
    end

    it "should update updated_at" do
      @customer.updated_at.should_not == Time.at(10)
      Time.stub! :now => Time.at(10)
      @customer.last_name = "Mr.BobDobalina"
      @customer.save!

      @customer.updated_at.should == Time.at(10)
    end

    it "should set changed_since_sync to true" do
      @customer.should_not be_changed_since_sync
      @customer.last_name = "Donaldson"
      @customer.save!
      @customer.should be_changed_since_sync
    end

    describe "if 'changes_from_quick_books' is set to true" do
      before do
        @customer.changes_from_quick_books = true
        @customer.last_name = "Spam"
        @customer.save!
      end

      it "should not be changed_since_sync" do
        @customer.should_not be_changed_since_sync
      end

      it "should reset 'changes_from_quick_books'" do
        @customer.changes_from_quick_books.should == false
      end
    end

  end

  describe "with associations" do
    before do
      customer = Resource.from_raw("Customer", {"name" => "Bob"}, {:quick_books_id => "abc123"})
      customer_2 = Resource.from_raw("Customer", {"name" => "Hezekiah"}, {:quick_books_id => "customer2"})

      item = Resource.from_raw("ItemService", {"name" => "Awesome"}, {:quick_books_id => "item123"})
      invoice_line = Resource.from_raw("InvoiceLine", {"quantity" => "5", "item" => item}, {})
      invoice = Resource.from_raw("Invoice", {"customer" => customer, "invoice_lines" => [invoice_line]}, {:quick_books_id => "xyz987"})

      invoice_line_2 = Resource.from_raw("InvoiceLine", {"quantity" => "10", "item" => item}, {})
      invoice_2 = Resource.from_raw("Invoice", {"customer" => customer_2, "invoice_lines" => [invoice_line_2]}, {:quick_books_id => "invoice2"})

      @repository.add ResourceSet.new([customer, invoice, item, customer_2, invoice_2])

      @customer = Customer.first :conditions => {:quick_books_id => "abc123"}
      @customer_2 = Customer.first :conditions => {:quick_books_id => "customer2"}

      @invoice = Invoice.first :conditions => {:quick_books_id => "xyz987"}
      @invoice_line = @invoice.lines.first

      @invoice_2 = Invoice.first :conditions => {:quick_books_id => "invoice2"}
      @invoice_line_2 = @invoice_2.lines.first
      @item = Item.first
    end

    it "should load 2 Customer" do
      Customer.count.should == 2
    end

    it "should load 2 Invoices" do
      Invoice.count.should == 2
    end

    it "should load 2 InvoiceLines" do
      InvoiceLine.count.should == 2
    end

    it "should load 1 Item" do
      Item.count.should == 1
    end

    describe "the first Invoice" do
      it "should have the correct customer" do
        @invoice.customer.should == @customer
      end
    end

    describe "the second Invoice" do
      it "should have the correct customer" do
        @invoice_2.customer.should == @customer_2
      end
    end



    describe "the Item" do
      subject { @item }
      it "should have the correct id" do
        subject.quick_books_id.should == "item123"
      end

      it "should have the correct name" do
        subject.name.should == "Awesome"
      end
    end

    it "should associated the customer with the invoice" do
      @invoice.customer.should == @customer
    end

    it "should associated the invoice lines " do
      @invoice.lines.length.should == 1
    end

    describe "the first invoice line" do

      it "should have associated item" do
        @invoice_line.item.should == @item
      end

      it "should have the correct quantity" do
        @invoice_line.quantity.should == 5
      end
    end

    describe "the second invoice line" do

      it "should have the associated item" do
        @invoice_line_2.item.should == @item
      end

    end

    describe "the loaded item" do
      subject { @item }

      it { should be_an(ItemService) }

      it "should have the correct attributes" do
        @item['name'].should == "Awesome"
      end

    end
  end

  describe "with a customer and associated invoice" do
    before do
      @ar_customer = Customer.create! :first_name => "Steve", :last_name => "Dave"
      @ar_invoice = Invoice.create! :customer => @ar_customer
      @ar_payment_method = PaymentMethod.create! :name => 'Chickens'
      @ar_item = ItemService.create! :name => "Awesome"
      @ar_line = InvoiceLine.create! :quantity => 42, :rate_in_cents => 500, :invoice => @ar_invoice, :item => @ar_item
      @ar_applied_to_txn = AppliedToTxn.create! :invoice => @ar_invoice, :payment_amount => '123.45'
      @ar_receive_payment = ReceivePayment.create! :customer => @ar_customer, :applied_to_txns => [@ar_applied_to_txn], :payment_method => @ar_payment_method


      @customer = @repository.resources.detect {|r| r.type == :Customer}
      @invoice = @repository.resources.detect {|r| r.type == :Invoice }
      @item = @repository.resources.detect {|r| r.type == :ItemService }
      @payment = @repository.resources.detect {|r| r.type == :ReceivePayment}
      @payment_method = @repository.resources.detect {|r| r.type == :PaymentMethod}
    end

    it "should have three resources (specifically, not the invoice line)" do
      @repository.resources.length.should == 5
    end

    it "should have the correct types" do
      @repository.resources.map(&:type).to_set.should == Set[:Customer, :Invoice, :ItemService, :ReceivePayment, :PaymentMethod]
    end

    it "should generate the correct JSON" do
      @repository.resources.to_json.should be_json(
      [
        ["Customer",
          {
            "name"=>"Steve Dave",
            "last_name"=>"Dave",
            "first_name"=>"Steve"},
          {
            "created_at"=>1138,
            "updated_at"=>1138,
            "local_id"=>@ar_customer.id.to_s
          }
        ],
        ["Invoice",
          {
          "invoice_lines"=>
            [["InvoiceLine",
              {"quantity"=>42, "rate" => "5.00", "item"=>"1"},
              {"created_at"=>1138, "updated_at"=>1138, "local_id"=>@ar_line.id.to_s}
            ]],
          "customer" => @ar_customer.id.to_s,
          },
          {
            "created_at"=>1138,
            "updated_at"=>1138,
            "local_id"=> @ar_invoice.id.to_s
          }
        ],
       ["ItemService",
        {"name"=>"Awesome"},
        {"created_at"=>1138, "updated_at"=>1138, "local_id"=>@ar_item.id.to_s}],
       ["PaymentMethod", {"name" => "Chickens"}, {"local_id" => @ar_payment_method.id.to_s, "updated_at" => 1138, "created_at" => 1138}],
       ["ReceivePayment", {"payment_method" => @ar_payment_method.id.to_s, "customer" => @ar_customer.id.to_s,
         "applied_to_txns"=>
          [["AppliedToTxn",
            {"invoice"=> @ar_invoice.id.to_s, "payment_amount"=>"123.45"},
            {"created_at"=>1138,
             "changed_since_sync"=>true,
             "updated_at"=>1138,
             "local_id"=>"1"}]],
         }, {"created_at"=>1138, "updated_at"=>1138, "local_id"=> @ar_receive_payment.id.to_s}]
      ])
    end

    it "should have an Customer and an Invoice" do
      @customer.should be_a(Resource::Customer)
      @invoice.should be_a(Resource::Invoice)
    end

    describe "the invoice" do

      it "should have one line" do
        @invoice['invoice_lines'].length.should == 1
      end

      describe "line" do
        before do
          @line = @invoice["invoice_lines"].first
        end

        it "should have the correct quantity" do
          @line['quantity'].should == 42
        end

        it "should be a QuickBooks resource" do
          @line.should be_a(Resource::InvoiceLine)
        end

        it "should have a nil quickbooks ID" do
          @line.id.should == [:InvoiceLine, nil]
        end

        describe "item" do
          before do
            @item = @line["item"]
          end

          it "should have the correct name" do
            @item["name"].should == "Awesome"
          end
        end
      end

      describe "associated customer" do
        it "should be the same object as the customer" do
          @invoice['customer'].should == @customer
        end

        it "should be a QuickBooks resource" do
          @invoice['customer'].should be_a(Resource::Customer)
        end
      end

    end

    describe "the payment" do
      describe "payment method" do
        before do
          @nested_payment_method = @payment['payment_method']
        end
        subject { @nested_payment_method }

        it { should be_a(Resource::PaymentMethod) }

        it { should == @payment_method }
      end

      it "should be applied to correct invoice" do
        @payment['applied_to_txns'].length.should == 1
      end

      describe "application to transasctions" do
        before do
          @application = @payment['applied_to_txns'].first
        end

        subject { @application }
        it { should be_a(Resource::AppliedToTxn) }

        it "should apply to the invoice" do
          @application['invoice'].should == @invoice
        end

      end
    end
  end

  describe Item do
    it "should not save unless it's a subclass of item" do
      lambda {Item.create! :name => "Foo"}.should raise_error
    end
  end

  context "empty InvoiceLine remotely" do
    before do
      @invoice_line = Resource.from_raw "InvoiceLine", {"item" => nil}, {}
      @customer = Resource.from_raw "Customer", {"name" => "Foo"}, {}
      @invoice = Resource.from_raw "Invoice", {"customer" => @customer, "invoice_lines" => [@invoice_line]}, {}
    end

    it "should add it" do
      @repository.add([@invoice])

      Invoice.count.should == 1
      @ar_invoice = Invoice.first
      @ar_invoice.lines.length.should == 1
    end
  end

  context "empty InvoiceLine in AR" do
    before do
      @ar_invoice = Invoice.create! :lines => [InvoiceLine.new]
    end

    it "should show it" do
      @repository.resources.to_json.should be_json([["Invoice", {"invoice_lines"=>[["InvoiceLine", {"rate"=>"0.00"}, {"created_at"=>1138, "updated_at"=>1138, "local_id"=>"1"}]]}, {"created_at"=>1138, "updated_at"=>1138, "local_id"=>"1"}]])
    end
  end

end
