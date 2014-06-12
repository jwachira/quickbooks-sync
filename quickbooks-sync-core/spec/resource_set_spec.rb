require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe QuickBooksSync::ResourceSet do

  ResourceSet = QuickBooksSync::ResourceSet

  describe "when creating from JSON" do
    context "with empty JSON string" do
      it "should return an empty resource set" do
        ResourceSet.from_json(%{}).should be_empty
      end
    end

    context "with empty JSON array" do
      it "should return an empty resource set" do
        ResourceSet.from_json(%{[]}).should be_empty
      end
    end

    context "with one valid item" do
      before do
        @resource_set = ResourceSet.from_json(%{[ [ "Customer", { "name": "TJ" }, {"quick_books_id": "abc123", "updated_at": 123123} ] ]})
      end

      it "should return a resource set with one resource" do
        @resource_set.size.should == 1
      end

      describe "its first resource" do
        before do
          @resource = @resource_set.first
        end

        it "should have the correct type" do
          @resource.type.should == :Customer
        end

        it "should have the correct attributes" do
          @resource["name"].should == "TJ"
        end

        it "should have the correct ID" do
          @resource.id.should == [:Customer, "abc123"]
        end

        it "should have the correct updated_at" do
          @resource.last_modified.should == Time.at(123123)
        end
      end
    end

    context "with one valid item and one nil item" do
      before do
        @resource_set = ResourceSet.from_json(%{[ [ "Customer", { "name": "TJ" }, {"quick_books_id": "abc123", "updated_at": 123123} ], null ]})
      end

      it "should return a resource set with one resource" do
        @resource_set.size.should == 1
      end

      describe "its first resource" do
        before do
          @resource = @resource_set.first
        end

        it "should have the correct type" do
          @resource.type.should == :Customer
        end

        it "should have the correct attributes" do
          @resource["name"].should == "TJ"
        end

        it "should have the correct ID" do
          @resource.id.should == [:Customer, "abc123"]
        end

        it "should have the correct updated_at" do
          @resource.last_modified.should == Time.at(123123)
        end
      end
    end


    context "with an invoice and a customer, the invoice having a reference to the customer" do
      subject {

        ResourceSet.from_json(
        [["Customer", {"name"=>"Bob"}, {"quick_books_id"=>"abc123"}],
         ["Invoice",
          {"invoice_lines"=>
            [["InvoiceLine", {"quantity"=>"5", "item"=>"item911"}, {}]],
           "customer"=>"abc123"},
          {"quick_books_id"=>"xyz987"}],
         ["ItemService", {"name"=>"Awesome"}, {"quick_books_id"=>"item911"}],
         ["PaymentMethod",
           { "name" => "Chickens" }, { "quick_books_id" => "paymentmethod" }],
         ["ReceivePayment",
           { "customer" => "abc123", "payment_method" => "paymentmethod", "applied_to_txns" => [
             ["AppliedToTxn", { "invoice" => "xyz987", "payment_amount" => "60.00" }, {}]]},
           {"quick_books_id" => "stevedave"}
          ]
         ].to_json
        )


      }

      it_should_match_the_complex_resource_set
    end
  end

  context "with one valid item with an ID" do
    it "should generate correct JSON" do
      resource_set = ResourceSet.new([resource("Customer", {"name" => "Bob"}, {:quick_books_id => "abc123"})])
      resource_set.to_json.should be_json([["Customer", {"name"=>"Bob"}, {"quick_books_id"=>"abc123"}]])
    end
  end

  context "with an invoice and a customer, the invoice having a reference to the customer" do
    before do
      @customer = resource("Customer", {"name" => "Bob"}, {:quick_books_id => "abc123"})
      @invoice = resource("Invoice", {"customer" => @customer}, {:quick_books_id => "xyz987"})
      @resource_set = ResourceSet.new([@customer, @invoice])
    end

    it "should serialize properly" do
      @resource_set.to_json.should be_json([["Customer", {"name"=>"Bob"}, {"quick_books_id"=>"abc123"}], ["Invoice", {"invoice_lines" => [], "customer"=>"abc123"}, {"quick_books_id"=>"xyz987"}]])
    end
  end

  context "with an invoice and a nil record" do
    before do
      @customer = resource("Customer", {"name" => "Bob"}, {:quick_books_id => "abc123"})
      @resource_set = ResourceSet.new([@customer, nil])
    end

    it "should serialize properly" do
      @resource_set.to_json.should be_json([["Customer", {"name"=>"Bob"}, {"quick_books_id"=>"abc123"}] ])
    end
  end


  describe "an invoice with a nested invoice line" do
    before do
      @customer = resource("Customer", {"name" => "Bob"}, {:quick_books_id => "abc123"})
      @invoice_line = resource("InvoiceLine", {"quantity" => "5"})
      @invoice = resource("Invoice", {"customer" => @customer, :invoice_lines => [@invoice_line]}, {:quick_books_id => "xyz987"})
      @resource_set = ResourceSet.new([@customer, @invoice])
    end

    it "should serialize properly" do
      @resource_set.to_json.should be_json([["Customer", {"name"=>"Bob"}, {"quick_books_id"=>"abc123"}], ["Invoice", {"invoice_lines"=>[["InvoiceLine", {"quantity"=>"5"}, {}]], "customer" => "abc123"}, {"quick_books_id"=>"xyz987"}]])
    end
  end

  describe "without a 'nil' for a nested resource" do
    it "should return an empty list" do
      @invoice = ResourceSet.from_json([["Invoice", {}, {}]].to_json).first
      @invoice['invoice_lines'].should == []
    end
  end
end
