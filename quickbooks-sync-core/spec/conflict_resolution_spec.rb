require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe QuickBooksSync, "when resolving conflicts" do

  def do_sync
    @session = QuickBooksSync::Session.sync(@qb, @remote)
  end

  describe "when vector clocks match" do
    before :each do
      @jim    = resource("Customer",
                         {"name" => "Jim"},
                         {:quick_books_id => "abc123", :vector_clock => "2"})
      @bob    = resource("Customer",
                         {"name" => "Bob"},
                         {:quick_books_id => "abc123", :vector_clock => "2"})
      @qb       = QuickBooksSync::Test::MockQBRepo.new [ @jim ]
      @remote   = new_local_repo [ @bob ]
    end

    it "should use the resources specified in the sync operation to resolve the conflicts" do
      do_sync
      @qb.resources.first.attributes[:name].should == 'Jim'
      @remote.resources.first.attributes[:name].should == 'Jim'
    end

    it "should have no conflicts" do
      do_sync.conflicts.should be_empty
    end
  end

  describe "when vector clocks differ" do
    before do
      @now    = Time.now
      @jim    = resource("Customer",
                         {"name" => "Jim", "is_active" => "true"},
                         {:quick_books_id => "abc123", :vector_clock => "2", :updated_at => Time.at(1)})
      @bob    = resource("Customer",
                         {"name" => "Bob", "is_active" => "true"},
                         {:quick_books_id => "abc123", :vector_clock => "1", :updated_at => Time.at(10), :changed_since_sync => true})

      @qb       = QuickBooksSync::Test::MockQBRepo.new [ @jim ]
      @remote   = new_local_repo [ @bob ]
    end

    it "should have one conflict" do
      do_sync.conflicts.length.should == 1
    end

    describe "the conflict" do
      subject { do_sync.conflicts.first }

      it { should be_a(QuickBooksSync::Conflict) }

      it "should enumerate the differences" do
        subject.differences.should == [[:name, ["Bob", "Jim"]]]
      end

      it "should have the correct #id" do
        subject.id.should == [:Customer, "abc123"]
      end

      it "should have the correct #unique_id" do
        subject.unique_id.should == "abc123"
      end

      it "should have the correct #type" do
        subject.type.should == :Customer
      end
    end

    describe "and resolutions are passed in" do
      def do_sync
        resolution = QuickBooksSync::Resolution.new ["Customer", "abc123"], {"name" => "Jim"}
        @session = QuickBooksSync::Session.sync(@qb, @remote, [resolution])
      end

      before do
        do_sync
      end

      it "should have no conflicts" do
        @session.conflicts.should be_empty
      end

      it "should have resolve the conflict per the specified resolution" do
        @qb.resources.first.attributes['name'].should == 'Jim'
        @remote.resources.first.attributes['name'].should == 'Jim'
      end

      it "should not overwrite the other fields" do
        @qb.resources.first[:is_active].should == "true"
        @remote.resources.first[:is_active].should == "true"
      end

      it "should update the vector clocks for the remote repo" do
        qb_resource = @qb.resources.first
        remote_resource = @remote.resources.first

        ["1", "2"].should_not include(qb_resource.vector_clock)
        remote_resource.vector_clock.should == qb_resource.vector_clock
      end

      it "should flip changed_since_sync" do
        @remote.resources.first.should_not be_changed_since_sync
      end


    end
  end

  describe "when vector clocks differ and the changes were made on the Quickbooks side" do
    before do
      @now    = Time.now
      @jim    = resource("Customer",
                         {"name" => "Jim", "is_active" => "true"},
                         {:quick_books_id => "abc123", :vector_clock => "2", :updated_at => @now})
      @bob    = resource("Customer",
                         {"name" => "Bob", "is_active" => "true"},
                         {:quick_books_id => "abc123", :vector_clock => "1", :updated_at => @now - 3, :changed_since_sync => false })
      @qb       = QuickBooksSync::Test::MockQBRepo.new [ @jim ]
      @remote   = new_local_repo [ @bob ]
    end

    before do
      @session = QuickBooksSync::Session.sync(@qb, @remote)
    end

    it "should have no conflicts" do
      @session.conflicts.should be_empty
    end

    it "should resolve to the Quickbooks side" do
      @remote.resources.first['name'].should == "Jim"
    end

  end

end
