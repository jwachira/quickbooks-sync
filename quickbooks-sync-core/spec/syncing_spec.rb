require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe QuickBooksSync::Repository do
  ResourceSet = QuickBooksSync::ResourceSet
  before do
    Time.stub! :now => Time.at(1358)
  end

  def mock_qb_repo(resources)
    repo = mock("QuickBooks Repo")
    repo.should_receive(:resources).once.and_return(resource_set(resources))
    repo
  end

  def resource_set(resources)
    QuickBooksSync::ResourceSet.new resources
  end

  describe "with one customer record in quickbooks and no records remotely" do
    before do
      @qb = mock_qb_repo [resource("Customer", {"name" => "Bob"}, {:quick_books_id => "abc123"})]
      # @qb.should_receive
      @remote = new_local_repo []

      QuickBooksSync::Session.sync(@qb, @remote)
    end

    describe "the remote repository" do
      it "should have one resource" do
        @remote.resources.length.should == 1
      end
    end

    describe "the synced resource" do
      before { @resource = @remote.resources.first }
      specify { @resource.id.should == [:Customer, "abc123"] }
      specify { @resource[:name].should == "Bob" }
    end

  end

  describe "with one customer records remotely and no records in quickbooks" do
    before do
      @qb = QuickBooksSync::Test::MockQBRepo.new []
      @remote = new_local_repo [resource("Customer", {"name" => "Bob"})]

      QuickBooksSync::Session.sync(@qb, @remote)
    end

    describe "the quickbooks repository" do
      it "should have one resource" do
        @qb.resources.length.should == 1
      end
    end

    describe "the synced resource" do
      before { @resource = @qb.resources.first }
      specify { @resource[:name].should == "Bob" }

      describe "#id" do
        subject { @resource.id }

        it { should_not be_nil }
        it { should be_an(Array) }
        it { should_not be_empty }

        it "should have 2 elements" do
          subject.length.should == 2
        end

        describe "the ID part" do
          subject { @resource.id.last }

          it { should_not be_nil }
          it { should be_a(String) }
          it { should_not be_empty }
        end

        describe "the type part" do
          subject { @resource.id.first }

          it "should be the type" do
            subject.should == :Customer
          end
        end

        it "should be equal to the ID set in the remote repository" do
          subject.should == @remote.resources.first.id
        end

      end
    end
  end

  describe "with one customer records remotely and a conflicting record in quickbooks, the quickbooks one edited later" do
    before do
      @qb = QuickBooksSync::Test::MockQBRepo.new [resource("Customer",
                            {"name" => "Jim"},
                            {:quick_books_id => "abc123", :updated_at => Time.at(15)})]
      @remote = new_local_repo [resource("Customer",
                            {"name" => "Bob"},
                            {:quick_books_id => "abc123", :updated_at => Time.at(10)})]

      @session = QuickBooksSync::Session.sync(@qb, @remote)
    end

    it "should not add extra resources" do
      @qb.resources.length.should == 1
      @remote.resources.length.should == 1
    end

    it "should have no conflicts" do
      @session.conflicts.should be_empty
    end

    describe "the remote repo" do
      subject { @remote.resources.first }
      it "should update the local repo to match the quickbooks one" do
        subject[:name].should == "Jim"
      end

      it "should have an updated timestamp" do
        subject.updated_at.should == Time.at(15)
      end
    end

    describe "the quickbooks repo" do
      subject { @qb.resources.first }

      it "should have not been altered" do
        subject[:name].should == "Jim"
      end

      it "should have an unaltered timestamp" do
        subject.updated_at.should == Time.at(15)
      end
    end

    describe "with one customer records remotely and a conflicting record in quickbooks, the remote one edited later" do
      before do
        @qb = QuickBooksSync::Test::MockQBRepo.new [resource("Customer",
                              {"name" => "Jim"},
                              {:quick_books_id => "abc123", :vector_clock => "1", :updated_at => Time.at(10)})]
        @remote = new_local_repo [resource("Customer",
                              {"name" => "Bob"},
                              {:quick_books_id => "abc123", :vector_clock => "1", :updated_at => Time.at(15), :changed_since_sync => true})]

        @session = QuickBooksSync::Session.sync(@qb, @remote)
      end

      it "should have no conflicts" do
        @session.conflicts.should be_empty
      end

      it "should not add extra resources" do
        @qb.resources.length.should == 1
        @remote.resources.length.should == 1
      end

      describe "the remote repo" do
        subject { @remote.resources.first }
        it "should not have changed" do
          subject[:name].should == "Bob"
        end

        it "should have an updated timestamp" do
          subject.updated_at.should == Time.at(15)
        end

        it { should_not be_changed_since_sync }
      end

      describe "the quickbooks repo" do
        subject { @qb.resources.first }

        it "should be updated to match the remote one" do
          subject[:name].should == "Bob"
        end

        it "should have an unaltered timestamp" do
          subject.updated_at.should == Time.at(15)
        end
      end


    end

  end

  describe "when syncing and there are merge conflicts" do
    before :each do
      @last_synced_at = Time.now
      @qb     = QuickBooksSync::Test::MockQBRepo.new [resource("Customer",
                                         {"name" => "Jim"},
                                         {:quick_books_id => "abc123", :vector_clock => "2",  :updated_at => (@last_synced_at + 10)})]
      # @qb.stub!(:last_synced_at).and_return(@last_synced_at)
      @remote = new_local_repo [resource("Customer",
                                         {"name" => "Bob"},
                                         {:quick_books_id => "abc123", :vector_clock => "1", :changed_since_sync => true})]

    end

    it "should return the conflict(s) within a session object" do
      session = QuickBooksSync::Session.sync(@qb, @remote)
      session.conflicts.size.should == 1
    end

    it "should allow iterating over the conflicts for processing" do
      session = QuickBooksSync::Session.sync(@qb, @remote)

      session.conflicts.first.differences.should == [[:name, ["Bob", "Jim"]]]
    end

    it "should not flip changed_since_sync" do
      @remote.resources.first.should be_changed_since_sync
    end
  end

  describe "when syncing and there are errors adding resources to the remote repository" do
    before :each do
      @customer = resource("Customer",
               {"name" => "Bob"},
               {:quick_books_id => "abc456", :vector_clock => "1", :changed_since_sync => true})

      @qb     = QuickBooksSync::Test::MockQBRepo.new [ @customer ]
      @remote = new_local_repo [ ]
      @remote.stub!(:add).and_return([ QuickBooksSync::Error.new(@customer, [ "full_name", "has already been taken" ]) ])
    end

    def do_sync
      @session = QuickBooksSync::Session.sync(@qb, @remote)
    end

    it "should have one error" do
      do_sync
      @session.remote_errors.size.should == 1
    end

    describe "the error" do
      before { do_sync }
      subject { @session.remote_errors.first }
      it "should have the correct message" do
        subject.message.should == "Full name has already been taken"
      end

      it "should have the corresponding resource" do
        subject.resource.should be_a(QuickBooksSync::Resource::Customer)
      end
    end
  end


  describe "when deleting a resource from quickbooks" do
    before do
      @qb = QuickBooksSync::Test::MockQBRepo.new [resource("Customer", {"name" => "Jim"}, {:quick_books_id => "abc123"})]
      @remote = new_local_repo [
        resource("Customer", {"name" => "Jim"}, {:quick_books_id => "abc123"}),
        resource("Customer", {"name" => "I've been deleted!"}, {:quick_books_id => "xyz987"})]

      QuickBooksSync::Session.sync(@qb, @remote)
    end

    it "should delete the record from the remote repo" do
      @remote.resources.length.should == 1
      resource = @remote.resources.first
      resource["name"].should == "Jim"
    end
  end

  describe "when syncing ReceivePayments" do
    describe "that exist on the remote and have a QB id" do
      before do
        @qb = QuickBooksSync::Test::MockQBRepo.new []
        @remote = new_local_repo [
          resource(:ReceivePayment, {}, {:quick_books_id => "abc123"})]
      end

      it "should not consider it deleted from QuickBooks" do
        @remote.should_not_receive(:delete)
        QuickBooksSync::Session.sync(@qb, @remote)
      end

      it "should not add them to quickbooks" do
        @qb.should_not_receive(:add)
        QuickBooksSync::Session.sync(@qb, @remote)
      end
    end

    describe "that exist on the remote and have not been synced" do
      before do
        @qb = QuickBooksSync::Test::MockQBRepo.new []
        @remote = new_local_repo [
          resource(:ReceivePayment, {}, {:local_id => "1"})]
      end

      it "should add them to quickbooks" do
        QuickBooksSync::Session.sync(@qb, @remote)
        @qb.resources.length.should == 1
      end
    end


  end

  describe "when deleting resources remotely" do
    before do
      @qb = QuickBooksSync::Test::MockQBRepo.new [resource("Customer", {"name" => "Jim"}, {:quick_books_id => "abc123"})]
      @remote = new_local_repo [resource("Customer", {"name" => "Jim"}, {:quick_books_id => "abc123", :deleted => true})]

      QuickBooksSync::Session.sync(@qb, @remote)
    end

    it "should delete them from quickbooks" do
      @qb.resources.should be_empty
    end

    it "should delete the tombstoned records from the remote repo" do
      @remote.resources.should be_empty
    end
  end

  describe "when making changes to Items" do
    before do
      @last_synced_at = Time.now
      @qb = QuickBooksSync::Test::MockQBRepo.new [resource("ItemService", {"name" => "Drug sales"},
        {:quick_books_id => "abc123",
        :vector_clock => "2",
        :updated_at => (@last_synced_at + 10)})]
      @remote = new_local_repo [resource("ItemService", {"name" => "I changed this"},
        {
          :quick_books_id => "abc123",
          :vector_clock => "2",
          :changed_since_sync => true,
          :updated_at => @last_synced_at + 15
        })]

      @session = QuickBooksSync::Session.sync(@qb, @remote)
    end

    it "should not have conflicts" do
      @session.conflicts.should be_empty
    end

    it "should change the remote item back to match the QB one" do
      @remote.resources.length.should == 1
      @remote.resources.first["name"].should == "Drug sales"
    end
  end

  describe "with no identical sets of items" do
    it "should add no items to remote" do
      @last_synced_at = Time.now
      resource = resource("ItemService", {"name" => "Drug sales"},
        {:quick_books_id => "abc123",
        :vector_clock => "2",
        :updated_at => (@last_synced_at + 10)})

      @qb = QuickBooksSync::Test::MockQBRepo.new [resource]
      @remote = new_local_repo [resource]

      @remote.should_not_receive(:add)

      @session = QuickBooksSync::Session.sync(@qb, @remote)
    end
  end

  describe "with alread-synced ReceivePayments" do
    before do
      resources = payment_dependent_on_invoice
      @remote_payment_add = resource(:ReceivePayment,
        {:customer        => resources[:customer],
        :applied_to_txns  => [ resources[:applied_to_txn] ],
        :payment_method => resources[:payment_method]}, {:quick_books_id => "foobar"})

      @qb_payment_add = resource(:ReceivePayment,
        {:customer        => resources[:customer],
        :applied_to_txns  => [ ],
        :payment_method => resources[:payment_method]}, {:quick_books_id => "foobar"})

      @qb = QuickBooksSync::Test::MockQBRepo.new [@remote_payment_add]
      @remote = new_local_repo [@qb_payment_add]
    end

    it "should not update remote repository if changes occur" do
      @qb.should_not_receive(:update)
      @remote.should_not_receive(:update)

      @session = QuickBooksSync::Session.sync(@qb, @remote)
    end
  end

  describe "with new ReceivePayments in QuickBooks" do
    before do
      resources = payment_dependent_on_invoice
      @remote_payment_add = resource(:ReceivePayment,
        {:customer        => resources[:customer],
        :applied_to_txns  => [ resources[:applied_to_txn] ],
        :payment_method => resources[:payment_method]}, {:quick_books_id => "foobar"})

      @qb_payment_add = resource(:ReceivePayment,
        {:customer        => resources[:customer],
        :applied_to_txns  => [ ],
        :payment_method => resources[:payment_method]}, {:quick_books_id => "foobar"})

      @qb = QuickBooksSync::Test::MockQBRepo.new [@remote_payment_add]
      @remote = new_local_repo []
    end

    it "should not add them to remote repo" do
      @remote.should_not_receive(:add)
      @session = QuickBooksSync::Session.sync(@qb, @remote)
    end


  end

  describe "an Invoice that has been updated in QuickBooks" do

    before do
      @qb_invoice = resource(:Invoice, {:lines => [], :balance_remaining => "0.00"}, {:quick_books_id => "invoice1"})
      @remote_invoice = resource(:Invoice, {:lines => [], :balance_remaining => "100.00"}, {:quick_books_id => "invoice1"})

      @qb = QuickBooksSync::Test::MockQBRepo.new [@qb_invoice]
      @remote = new_local_repo [@remote_invoice]
    end

    it "should update the remote repo" do
      QuickBooksSync::Session.sync(@qb, @remote)

      @remote.resources.first[:balance_remaining].should == "0.00"
    end
  end

  describe "a CreditMemo from QuickBooks" do
    before do
      @qb_credit_memo = resource(:CreditMemo, {:balance_remaining => "123.45"}, {:quick_books_id => "abc123"})

      @qb = QuickBooksSync::Test::MockQBRepo.new [@qb_credit_memo]
      @remote = new_local_repo []
    end

    it "should not add it to remote" do
      @remote.should_not_receive :add
      QuickBooksSync::Session.sync(@qb, @remote)
    end
  end
  
  describe "a CreditMemo from QuickBooks that has been changed, and a CreditMemo remotely" do
    before do
      @qb_credit_memo = resource(:CreditMemo, {:balance_remaining => "10.10"}, {:quick_books_id => "abc123", :vector_clock => "3", :updated_at => Time.at(10)})
      @remote_credit_memo = resource(:CreditMemo, {:balance_remaining => "123.45"}, {:quick_books_id => "abc123", :vector_clock => "2", :updated_at => Time.at(1)})

      @qb = QuickBooksSync::Test::MockQBRepo.new [@qb_credit_memo]
      @remote = new_local_repo [@remote_credit_memo]
    end
    
    it "should not modify the remote CreditMemo" do
      @remote.should_not_receive :update
      QuickBooksSync::Session.sync(@qb, @remote)
    end
  end



end
