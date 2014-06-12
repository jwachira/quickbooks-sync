require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ostruct'

describe "Remote Server / Remote Client interactions" do
  ResourceSet = QuickBooksSync::ResourceSet

  Resource = QuickBooksSync::Resource

  describe "with proper authentication and correct versions" do
    before do
      @repository = mock("Repository")
      @server = QuickBooksSync::Server.create(:repository => @repository, :version => "foobar")
      @remote_client = QuickBooksSync::Repository::Remote.new(:host => 'localhost', :version => "foobar")

      @remote_client.connection.stub! :client => RackTestClient.new(@server)
    end

    class RackTestClient
      def initialize(app)
        @app = app
      end

      attr_reader :app

      def session
        Rack::Test::Session.new(Rack::MockSession.new(app))
      end

      def execute(opts)
        method = opts[:method]
        path = opts[:path]
        body = opts[:payload] || ""
        headers = opts[:headers].inject({}) {|_, (k, v)| _.merge(convert_header(k) => v) }

        rack_response = session.send(method, path, body, headers)

        OpenStruct.new :code => rack_response.status.to_i, :body => rack_response.body

      end

      [:get, :post, :put, :delete].each do |method|
        define_method(method) do |path, options|
          execute(
            :method => method,
            :path => path,
            :payload => options[:body],
            :headers => options[:headers]
          )
        end
      end

      private

      def convert_header(header)
        "HTTP_" + header.to_s.upcase.gsub("-", "_")
      end
    end

    def app
      @server
    end

    describe "#get" do
      describe "with no resources" do
        it "should return an empty set" do
          @repository.should_receive(:resources).and_return(ResourceSet.new([]))
          @remote_client.resources.should == ResourceSet.new({})
        end
      end

      describe "with complex resources" do
        before do
          @repository.should_receive(:resources).and_return(complex_resource_set)
        end

        subject { @remote_client.resources }

        it_should_match_the_complex_resource_set
      end
    end

    describe "#add" do
      context "successful" do
        it "should add to remote repo" do
          @repository.should_receive(:add).with(complex_resource_set).and_return([])
          @remote_client.add(complex_resource_set).should == []
        end
      end

      context "with errors" do
        Error = QuickBooksSync::Error

        before do
          @customer = complex_resource_set.detect {|r| r.type == :Customer }
        end
        
        it "should report its errors" do
          @repository.should_receive(:add).with(complex_resource_set).and_return([ Error.new(@customer, [ 'some_field', "OH SNAP" ]) ])
          error = @remote_client.add(complex_resource_set).first
          error.message.should == "Some field OH SNAP"
          error.resource.should == @customer
        end
      end
    end

    describe "#update" do

      it "should update remote repo" do
        @repository.should_receive(:update).with(complex_resource_set).and_return(complex_resource_set)
        @remote_client.update(complex_resource_set)
      end
    end

    describe "#update_metadata" do
      it "should update metadata on repmote repo" do
        metadata = {["Customer", 42] => {:quick_books_id => "xyz987", :created_at => Time.at(42)}}
        expected = [[["Customer", 42], {:quick_books_id => "xyz987", :created_at => Time.at(42)}]]
        @repository.should_receive(:update_metadata).with(expected).and_return({})
        @remote_client.update_metadata(metadata)
      end
    end

    describe "#mark_as_synced" do
      it "should proxy it to repo" do
        @repository.should_receive(:mark_as_synced)
        @remote_client.mark_as_synced
      end
    end

    describe "#log" do
      it "should proxy it to the repo" do
        @repository.should_receive(:respond_to?).with(:log).and_return(true)
        @repository.should_receive(:log).with("foo bar")
        @remote_client.log("foo bar")
      end
    end

  end

  describe "with mismatched versions" do
    before do
      @repository = mock("Repository", :client_download_url => "http://foo.com/qb-sync.exe")
      @server = QuickBooksSync::Server.create(:repository => @repository, :version => "A")
      @remote_client = QuickBooksSync::Repository::Remote.new(:host => 'localhost', :version => "B")
      @remote_client.connection.stub! :client => RackTestClient.new(@server)


      @repository.should_not_receive(:resources)
      @exception = begin
        @remote_client.resources
      rescue Exception => e
        e
      end
    end


    describe "should raise an error that" do

      subject { @exception }

      it { should_not be_nil }
      it { should be_a(QuickBooksSync::VersionMismatch) }

      specify { @exception.client_download_url.should == "http://foo.com/qb-sync.exe"}
    end
  end

  describe "with incorrect authentication" do
    before do
      @repository = mock("Repository")
      @server = QuickBooksSync::Server.create(:repository => @repository, :version => "A")
    end

    it "should be forbidden" do
      @repository.should_not_receive(:resources)
      response = RackTestClient.new(@server).execute(
        :method => :get,
        :path => "/resources",
        :headers => {"X_CLETUS_SIGNATURE" => "h4x0r"})

      response.code.should == 403
    end
  end

  describe "with empty authorization" do
    before do
      @repository = mock("Repository")
      @server = QuickBooksSync::Server.create(:repository => @repository, :version => "A")
    end

    it "should be forbidden" do
      @repository.should_not_receive(:resources)
      response = RackTestClient.new(@server).execute(
        :method => :get,
        :path => "/resources",
        :headers => {})

      response.code.should == 403

    end
  end

  describe "when errors are thrown" do
    before do
      @repository = mock("Repository")
      @server = QuickBooksSync::Server.create(:repository => @repository, :version => "A")
      @remote_client = QuickBooksSync::Repository::Remote.new(:host => 'localhost', :version => "A")

      @remote_client.connection.stub! :client => RackTestClient.new(@server)

      @repository.should_receive(:resources).and_raise(FooBarException.new)
      @exception = begin
        @remote_client.resources
      rescue Exception => e
        e
      end

    end

    class FooBarException < Exception
    end

    describe "the exception thrown" do
      subject { @exception }

      it { should_not be_nil }
      it { should be_a(QuickBooksSync::ServerError) }
      specify { @exception.to_s.should == "FooBarException" }
    end
  end

end
