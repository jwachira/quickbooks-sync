# Architecture #

* Quickbooks API

  Send an XML document; get an XML document back.  A request document can have a series of "requests", each indexed by a unique ID.  The response document contains a series of responses, each correlated to a given request.  Besides that, everything is terrible about this API.  Resources have IDs, unless they're nested, like InvoiceLine in Invoice.  IDs are either ListIDs or TxnIDs depending on the type.  Resources have a vector clock (EditSequence) that is updated by Quickbooks.  Trying to update a resource while supplying an incorrect EditSequence won't work.  We can use this to track if changes have been made on the QuickBooks side.

* QuickBooks connection (quickbooks-sync-connection)

  Passes XML strings to QuickBooks API.  Uses Win32 COM and JACOB (Java / COM bridge).  Works only in JRuby running on Windows.  Mocked out for testing.

* Client (client.rb)

  Batches requests together and executes Ruby blocks as callbacks to given requests.  Generally passes XML fragments through unmolested.

* Resource (abstract\_resource.rb)

  Represents a QuickBooks resource.  This can be a Customer, Invoice, Invoice Line Item, or anything else.  Metadata about validation, references, nestedness, etc are drawn from types.rb (generated from the QuickBooks XSD file) and type\_metadata.rb (written by hand).  Has Resource, a concrete implementation written mostly for testing, Resource::JSON, which is backed by a data structure derived from JSON, and Resource::XML, which is backed by an XML fragment generated from Quickbooks.

  The abstract base class supports serializing all of these to JSON/XML and dealing with references/nested stuff.

* ResourceSet (resource\_set.rb)

  Represents a set of Resources.  Can perform aggregate operations on said set.  Supports serializing to JSON.

*  Repository::QuickBooks (repository/quick_books.rb)

  Implements \#add, \#delete, \#update, \#update\_metadata, and \#resources.  These methods add resources or return resources.  \#add and \#update return updated metadata.

* ActsAsQuickBooksResource::Repository

  Implements a remote repository that works much like QuickBooks.  Takes a Resources and transforms them to ActiveRecord objects, saving them, etc.

* Server / Repository::Remote

  Sinatra App that wraps a repository as an HTTP server.  Uses JSON to communicate.  Ideally, wrapping an arbitrary repository with the Server and accessing it using Repository::Remote should perform identically to accessing it directly.
  * The version is locked to a string set in quick\_books\_sync\_ui/bin/jar_start.rb; if the corresponding string passed to ITUQuickBooksRepo.create doesn't matched, the user is prompted to download (via a signed URL) the file qb-sync-production.exe in the qb-cruft S3 bucket.

* Session (session.rb)

  Performs much of the actual syncing logic, checking if resources are up to date

* UI

  Uses JRuby/SWT with a web control (embedded IE instance) using Javascript to interface with Session.  A little messy, but it runs in Windows and works.
  * To package, install JRuby using RVM.  Then,
        
        rvm use jruby
        
        gem install bundler # (if necessary)
        
        cd quickbooks-sync-ui
        
        bundle install
        
        rake exe
        
  * The resulting package/qb-sync.exe should be ready for distribution
  * To distribute, run `rake dist`.  This will upload the executable to the correct S3 bucket.  Incrementing the version numbers and deploying should result in a somewhat seamless upgrade process.


# Debugging on remote machine #

If you have a packaged .exe file available on a remote server and want to debug using JRuby console, here are the steps to get the environment running.

    java -cp qb-sync-[environment].exe org.jruby.Main -S irb
    require 'load_from_jar'
    repo = QuickBooksSync::Repository::QuickBooks.with_connection(QuickBooksSync::Connection.new)
