module ResourceSetMatcher
  Resource = QuickBooksSync::Resource

  def it_should_match_the_complex_resource_set
    before do
      @resource_set = subject

      @customer = @resource_set.detect {|r| r.type == :Customer}
      @invoice = @resource_set.detect {|r| r.type == :Invoice}
      @item = @resource_set.detect {|r| r.type == :ItemService}
      @receive_payment = @resource_set.detect {|r| r.type == :ReceivePayment}
      @payment_method = @resource_set.detect {|r| r.type == :PaymentMethod}
    end

    specify { @resource_set.size.should == 5}

    describe "the customer" do
      it "should have the proper attributes" do
        @customer["name"].should == "Bob"
      end
    end

    describe "the invoice" do
      it "should have a reference to the customer" do
        @invoice["customer"].should == @customer
      end

      it "should have the correct item" do
        @invoice["customer"].should be_a(Resource::Customer)
      end


      it "should have an one invoice line" do
        @invoice["invoice_lines"].length.should == 1
      end

      describe "line items" do
        before { @line = @invoice["invoice_lines"].first }

        it "should have the correct item" do
          @line.should be_a(Resource::InvoiceLine)
        end

        it "should have the correct type" do
          @line.type.should == :InvoiceLine
        end

        it "should have the correct quantity" do
          @line["quantity"].should == "5"
        end

        describe "the item" do
          before { @item = @line["item"] }

          it "should have the correct item" do
            @item.should be_a(Resource::ItemService)
          end

        end
      end
    end

    describe "the payment method" do
      specify { @payment_method['name'].should == 'Chickens' }
    end

    describe "the received payment" do
      specify { @receive_payment['customer'].should be_a(Resource::Customer) }
      specify { @receive_payment['applied_to_txns'].length == 1 }
      describe "transaction application" do
        before do
          @applied_to_txn = @receive_payment['applied_to_txns'].first
        end

        specify { @applied_to_txn['invoice'].should be_a(Resource::Invoice) }
      end
    end

  end
end