require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

unless JRUBY #TODO: why is this so slow in jruby
  describe QuickBooksSync::XsdParser do

    before(:all) do
      file = File.expand_path(File.dirname(__FILE__) + '/../xml/qbxmlops60.xsd')
      # I DO WHAT I WANT
      @results = ($_qb_generate ||= QuickBooksSync::XsdParser.generate file)
    end

    it "should have only the following keys" do
      @results.keys.to_set.should == Set[
        "Customer",
        "Item",
        "Invoice",
        "InvoiceLine",
        "ItemInventory",
        "ItemPayment",
        "ItemDiscount",
        "ItemNonInventory",
        "ItemSalesTaxGroup",
        "ItemFixedAsset",
        "ItemService",
        "ItemGroup",
        "ItemInventoryAssembly",
        "ItemSalesTax",
        "ItemSubtotal",
        "ItemOtherCharge",
        "PaymentMethod",
        "ReceivePayment",
        "AppliedToTxn",
        "CreditMemo",
        "CreditMemoLine",
      ]
    end

    it "should generate attributes for Customer" do
      @results.keys.should include("Customer")
    end

    it "should generate attributes for Invoice" do
      @results.keys.should include("Invoice")
    end

    it "should generate attributes for other resources types" do
      pending
    end

    describe "generated Invoice attributes" do
      it "should be top level" do
        @results["Invoice"][:top_level].should == true
      end

      it "should include line items" do
        @results["Invoice"][:include_line_items].should == true
      end

      it "should not be deletable" do
        @results["Invoice"][:deletable].should == false
      end

      it "should not be abstract" do
        @results["Invoice"][:abstract].should == false
      end

      before(:all) { @invoice = @results["Invoice"][:fields] }

      it "should identify txn_id as the correct key" do
        @results["Invoice"][:key_name].should == "TxnID"
      end

      it "should get the attribute names in the correct order" do
        @invoice.map {|a| a[:name]}.should == ["customer",
         "class",
         "ar_account",
         "template",
         "txn_date",
         "ref_number",
         "bill_address",
         "ship_address",
         "is_pending",
         "po_number",
         "terms",
         "due_date",
         "sales_rep",
         "fob",
         "ship_date",
         "ship_method",
         "item_sales_tax",
         "memo",
         "customer_msg",
         "is_to_be_printed",
         "is_to_be_emailed",
         "is_tax_included",
         "customer_sales_tax_code",
         "other",
         "invoice_lines",
         "invoice_line_groups"]
      end

      describe "invoice lines" do
        subject { invoice_attributes["invoice_lines"] }

        it "should be of nested type" do
          subject[:type].should == :nested
        end

        it "should refer to the InvoiceLine resource type" do
          subject[:target].should == "InvoiceLine"
        end

        it "should have the proper XML element name" do
          subject[:element_name].should == "InvoiceLineRet"
        end
      end

      describe "customer reference" do
        before { @ref = invoice_attributes["customer"] }

        it "should identify customer ref as a reference" do
          @ref[:type].should == :ref
        end

        it "should identify the ref as targeting Customer" do
          @ref[:target].should == "Customer"
        end

        it "should have the proper XML element name" do
          @ref[:element_name].should == "CustomerRef"
        end

        it "should have :required, :type, :target, and :name as its keys" do
          Set[*@ref.keys].should == Set[:required, :type, :element_name, :target, :name]
        end
      end
    end

    describe "generated Customer attributes" do

      it "should not be abstract" do
        @results["Customer"][:abstract].should == false
      end

      it "should be top level" do
        @results["Customer"][:top_level].should == true
      end

      it "should be deletable" do
        @results["Customer"][:deletable].should == true
      end

      it "should identify list_id as the correct key" do
        @results["Customer"][:key_name].should == "ListID"
      end

      before(:all) { @customer = @results["Customer"][:fields] }

      it "should get the attributes names in the correct order" do
        @customer.map {|a| a[:name] }.should == ["name",
         "is_active",
         "parent",
         "company_name",
         "salutation",
         "first_name",
         "middle_name",
         "last_name",
         "suffix",
         "bill_address",
         "ship_address",
         "print_as",
         "phone",
         "mobile",
         "pager",
         "alt_phone",
         "fax",
         "email",
         "contact",
         "alt_contact",
         "customer_type",
         "terms",
         "sales_rep",
         "sales_tax_code",
         "item_sales_tax",
         "sales_tax_country",
         "resale_number",
         "account_number",
         "credit_limit",
         "preferred_payment_method",
         "credit_card_info",
         "job_status",
         "job_start_date",
         "job_projected_end_date",
         "job_end_date",
         "job_desc",
         "job_type",
         "notes",
         "price_level"]
      end

      it "should identify the maximum length constraint" do
        customer_attributes["name"][:max_length].should == 41
      end

      it "should identify String types" do
        customer_attributes["name"][:type].should == :string
      end

      it "should have the proper XML element name" do
        customer_attributes["name"][:element_name].should == "Name"
      end

      it "should identify boolean types" do
        customer_attributes["is_active"][:type].should == :boolean
      end

      it "should identify enums and extract their options" do
        customer_attributes["job_status"][:type].should == :enum
        customer_attributes["job_status"][:choices].should == [
          "Awarded", "Closed", "InProgress", "None", "NotAwarded", "Pending"]
      end

      it "should identify amount types" do
        # what is an amount
        customer_attributes["credit_limit"][:type].should == :amount
      end

      it "should not include list_id" do
        customer_attributes.should_not include("list_id")
      end

      it "should not include edit_sequence" do
        customer_attributes.should_not include("edit_sequence")
      end

      it "should extract attributes that were included in a group" do
        customer_attributes.should include("phone")
      end

    end

    def invoice_attributes
      map_by_name(@invoice)
    end

    def invoice_line_attributes
      map_by_name(@invoice_line)
    end

    def customer_attributes
      map_by_name(@customer)
    end

    def map_by_name(attrs)
      attrs.to_hash_keyed_by {|a| a[:name] }
    end

    describe "generated InvoiceLine attributes" do
      before(:all) do
        @invoice_line = @results["InvoiceLine"][:fields]
      end

      it "should not be top-level" do
        @results["InvoiceLine"][:top_level].should == false
      end

      it "should have quantity type" do
        invoice_line_attributes["quantity"][:type].should == :quantity
      end

      it "should have Item ref" do
        {:type=>:ref, :target=>"Item", :name=>"item", :element_name=>"ItemRef"}
      end
    end

    %w{ItemService ItemNonInventory ItemOtherCharge ItemInventory ItemInventoryAssembly ItemFixedAsset}.each do |type|
      describe "generated #{type} attributes" do

        subject { @results[type] }

        it "should be top_level" do
          subject[:top_level].should == true
        end

        it "should not be abstract" do
          subject[:abstract].should == false
        end
      end
    end

    describe "generated Item attributes" do
      subject { @results["Item"] }

      it "should be abstract" do
        subject[:abstract].should == true
      end

      it "should list its concrete subclasses" do
        subject[:concrete_subtypes].to_set.should == Set["ItemInventory", "ItemPayment", "ItemDiscount", "ItemNonInventory", "ItemSalesTaxGroup", "ItemFixedAsset", "ItemService", "ItemGroup", "ItemInventoryAssembly", "ItemSalesTax", "ItemSubtotal", "ItemOtherCharge"]
      end
    end


  end

end