require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe QuickBooksSync::Resource do
  Resource = QuickBooksSync::Resource
  before do
    @resource = resource 'Customer', {'name' => 'Name'}
  end

  subject { @resource }

  describe "#==" do
    describe "if all attributes are the same" do
      before do
        @a = resource 'Customer', {'first_name' => 'Bob'}, {:quick_books_id => "abc123"}
        @b = resource 'Customer', {'first_name' => 'Bob'}, {:quick_books_id => "abc123"}
      end

      it "should return true" do
        @a.should == @b
      end
    end

    describe "where the shared subset of attributes are the same" do
      before do
        @a = resource 'Customer', {'first_name' => 'Bob', 'job_status' => 'None'}, {:quick_books_id => "abc123"}
        @b = resource 'Customer', {'first_name' => 'Bob'}, {:quick_books_id => "abc123"}
      end
      it "should return true" do
        @a.should == @b
      end
    end

    describe "if only id differs" do
      before do
        @a = resource 'Customer', {'first_name' => 'Bob'}, {:quick_books_id => "xyz987"}
        @b = resource 'Customer', {'first_name' => 'Bob'}, {:quick_books_id => "abc123"}
      end
      it "should be false" do
        @a.should_not == @b
      end
    end

    describe "if only type differs" do
      before do
        @a = resource 'Customer', {}
        @b = resource 'Invoice', {}
      end

      it "should return false" do
        @a.should_not == @b
      end
    end

    describe "with nested resources" do
      before do
        @a_invoice_line = resource 'InvoiceLine', {'quantity' => 5, 'rate' => "5.00"}
        @a_customer = resource 'Customer', {'name' => "Steve Dave"}, {:quick_books_id => "abc123"}
        @a_invoice = resource "Invoice", {"customer" => @a_customer, "invoice_lines" => [@a_invoice_line]}, {:quick_books_id => "a"}

        @b_invoice_line = resource 'InvoiceLine', {'quantity' => 5, 'rate' => "5.00"}
        @b_customer = resource 'Customer', {'name' => "Steve Dave"}, {:quick_books_id => "abc123"}
        @b_invoice = resource "Invoice", {"customer" => @b_customer, "invoice_lines" => [@b_invoice_line]}, {:quick_books_id => "a"}
      end

      it "should return true" do
        @b_invoice.should == @a_invoice
      end
    end

  end

  describe "#[]" do
    describe "to a valid attribute" do
      it "should return the attribute value" do
        @resource['name'].should == 'Name'
      end
    end

    describe "to an invalid attribute" do
      before do
        @resource = resource 'Customer', {'foo' => 'bar'}
      end

      it "should return nil" do
        @resource['foo'].should == nil
      end
    end

    describe "#attributes" do
      it "should return a hash of valid attributes" do
        @resource.attributes.should == {:name=>"Name"}
      end
    end
  end

  describe "#attributes" do
    it "should return a hash of valid attributes" do
      @resource.attributes.should == {:name=>"Name"}
    end
  end

  describe "with valid attributes" do
    it { should be_valid }
  end

  describe "with valid attributes" do
    it { should be_valid }
    it "should have no errors" do
      @resource.errors.should be_empty
    end
  end

  describe "with an invalid type" do
    it "should raise an error" do
      lambda { resource "ThingAmaJigger", {"omg" => "wtfbbq"}}.should raise_error
    end
  end

  describe "with invalid attributes" do
    describe "that include a string that's too long" do
      before do
        @resource = resource "Customer", 'name' => "too long"*500
      end

      it { should_not be_valid }

      it "should have an error saying so" do
        @resource.errors.keys.should == [:name]
        # TODO: pretty error messages?
        @resource.errors[:name].should include("4000 > 41")
      end
    end

    describe "that include an enum that doesn't match the choices" do
      before do
        @resource = resource "Customer", 'job_status' => 'shitcanned!'
      end

      it { should_not be_valid }

      it "should have an error saying so" do
        @resource.errors.keys.should == [:job_status]
        @resource.errors[:job_status].should == '"shitcanned!" not a valid choice'
      end
    end
  end

  describe "an unadded resource" do
    it { should_not be_added }
  end

  describe "already synced from quickbooks" do
    before do
      @resource = resource 'Customer', {'name' => 'Name'}, {:quick_books_id => 'abc123', :vector_clock => '92312321'}
    end

    describe "#id" do
      it "should return the quickbooks id" do
        @resource.id.should == [:Customer, 'abc123']
      end
    end

    describe "#vector_clock" do
      it "should return the vector clock's value" do
        @resource.vector_clock.should == '92312321'
      end
    end

  end

  describe "#added?" do
    describe "with no qb id" do
      subject { resource 'Customer', {'name' => 'Foo'}}
      it { should_not be_added }
    end

    describe "with a qb id" do
      subject { resource 'Customer', {'name' => 'Foo'}, {:quick_books_id => 'abc123'}}
      it { should be_added }
    end

  end

  describe "#changed_since_sync?" do
    describe "when set to true in provided metadata" do
      subject {resource 'Customer', {'name' => 'foo'}, {:changed_since_sync => true}}
      it { should be_changed_since_sync }
    end

    describe "when not set in provided metadata" do
      subject {resource 'Customer', {'name' => 'foo'}, {}}
      it { should_not be_changed_since_sync }
    end

    describe "when set to false in provided metadata" do
      subject {resource 'Customer', {'name' => 'foo'}, {:changed_since_sync => false}}
      it { should_not be_changed_since_sync }
    end

  end

  describe "#quick_books_id" do
    before do
      @resource = resource 'Customer', {'name' => 'Foo'}, {:quick_books_id => "987"}
    end

    it "should set metadata[:quick_books_id]" do
      @resource.metadata[:quick_books_id].should == "987"
    end

    it "should set id" do
      @resource.id.should == [:Customer, "987"]
    end
  end

  describe "#fields" do
    before do
      @resource = resource 'Customer', {}
    end

    it "should give list of fields" do
      @resource.fields.map(&:name).to_set.should ==  Set[:name, :is_active, :company_name, :first_name, :last_name, :suffix, :phone, :email, :job_status]
    end
  end

  describe "#references" do
    before do
      @resource = resource 'Invoice', {}
    end

    it "should return the possible references for a resource" do
      @resource.references.map(&:name).should == [:customer]
    end
  end

  describe "#dependencies" do
    before do
      @customer = resource 'Customer', {'name' => "Steve Dave"}
      @item = resource 'ItemService', {'name' => "Awesome"}
      @invoice_line = resource 'InvoiceLine', {'quantity' => "42", 'item' => @item}
      @invoice = resource 'Invoice', {'customer' => @customer, 'invoice_lines' => [@invoice_line]}
    end

    it "should return all non-nested dependencies for a resource" do
      @invoice.dependencies.should == [@customer, @item]
    end

    context "with a payment" do
      before do
        resources = payment_dependent_on_invoice
        @invoice = resources[:invoice]
        @payment_add = resources[:payment_add]
      end

      it "should specify the invoice as one of its dependencies" do
        @payment_add.dependencies.should include(@invoice)
      end
    end
  end

  describe "the expected resource", :shared => true do
    it "should have a quickbooks id" do
      subject.id.should == ["Customer", "abc123"]
    end
  end

  describe "#concrete_superclass" do
    before do
      @item = resource 'ItemService', {'name' => "Awesome"}
    end

    it "should point to its concrete superclass, used for lookups" do
      @item.concrete_superclass.should == Resource::Item
    end
  end


  describe "#to_xml" do
    include XmlMatchers

    describe "with a new resource" do
      before do
        @customer = resource 'Customer', {'name' => "Steve Dave"}
      end

      it "should retrn the proper XML" do
        @customer.to_xml(:add).should be_xml("<CustomerAdd><Name>Steve Dave</Name></CustomerAdd>")
      end

      describe "with a numeric value" do
        before do
          @invoice_line = resource 'InvoiceLine', {'quantity' => 5, 'rate' => "5.00"}
        end
        it "should create the proper XML" do
          @invoice_line.to_xml(:add).should be_xml(
          "<InvoiceLineAdd>
             <Quantity>5</Quantity>
             <Rate>5.00</Rate>
          </InvoiceLineAdd>")
        end
      end

      describe "with an Invoice" do
        before do
          @invoice_line = resource 'InvoiceLine', {'quantity' => 5, 'rate' => "5.00"}
          @customer = resource 'Customer', {'name' => "Steve Dave"}, {:quick_books_id => "abc123"}
          @invoice = resource "Invoice", {"customer" => @customer, "invoice_lines" => [@invoice_line]}
        end

        it "should return the XML with the nested values" do
          @invoice.to_xml(:add).should be_xml(
            "<InvoiceAdd>
               <CustomerRef>
                  <ListID>abc123</ListID>
               </CustomerRef>
               <InvoiceLineAdd>
                  <Quantity>5</Quantity>
                  <Rate>5.00</Rate>
               </InvoiceLineAdd>
            </InvoiceAdd>")
        end
      end

      describe "with an Invoice with a customer which has an error state" do
        before do
          @invoice_line = resource 'InvoiceLine', {'quantity' => 5, 'rate' => "5.00"}
          @customer = resource 'Customer', {'name' => "Steve Dave"}, {:quick_books_id => "abc123"}
          @invoice = resource "Invoice", {"customer" => @customer, "invoice_lines" => [@invoice_line]}
        end

        it "should return the XML with the nested values" do
          @invoice.to_xml(:add).should be_xml(
            "<InvoiceAdd>
               <CustomerRef>
                  <ListID>abc123</ListID>
               </CustomerRef>
               <InvoiceLineAdd>
                  <Quantity>5</Quantity>
                  <Rate>5.00</Rate>
               </InvoiceLineAdd>
            </InvoiceAdd>")
        end
      end
    end

  end

  describe "#eql?" do
    before do
      @customer = resource('Customer', {'name' => 'Steve Dave'})
    end

    it "should description" do
      @customer.should eql(@customer.dup)
    end
  end

end
