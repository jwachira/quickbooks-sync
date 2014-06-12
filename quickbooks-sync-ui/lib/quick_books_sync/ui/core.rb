require 'quick_books_sync/ui/swt/swt_wrapper'
require 'quick_books_sync/connection'
require 'erb'
require 'exceptional'
require 'active_support/core_ext/time/acts_like'
require 'active_support/core_ext/time/calculations'
require 'active_support/core_ext/numeric/time'


Exceptional.configure "562a989335587557ba289fc00c341c66c64c5fc6"
class Exceptional::Config
  def self.should_send_to_api?; true; end
end

module QuickBooksSync
  class UI

    include Helpers
    include Swt
    include Swt::Widgets

    HEIGHT = 600
    WIDTH = 400
    MARGIN = 5

    attr_accessor :next_scheduled_sync, :syncing

    def start
      shell.set_size HEIGHT, WIDTH
      shell.set_text "QuickBooks Sync - #{options[:remote]}"

      display_warning_message


      wait_and_run_at(options[:run_automatically_at]) if options[:run_automatically_at]

      @browser = Browser.new shell, SWT::NONE
      browser.set_bounds MARGIN, MARGIN, (HEIGHT - MARGIN), (WIDTH - MARGIN)

      SyncCallback.new(browser, self)

      shell.open
      self.html = erb("sync.html.erb", :locals => {:conflicts => [], :local_errors => [], :remote_errors => [], :status => nil})




      while !shell.is_disposed
        display.sleep unless display.read_and_dispatch
        begin
          browser_queue.pop(true).execute(self)
        rescue ThreadError => e
        end
      end

      display.dispose

      exit
    end

    attr_reader :browser, :browser_queue, :display, :options, :shell, :next_scheduled_sync

    def self.start(options={})
      new(options).start
    end

    def wait_and_run_at(time)
      time = Time.parse(time) unless time.is_a?(Time)
      self.next_scheduled_sync = time

      Thread.new do
        sleep 1

        loop do
          update_status("Syncing at #{(next_scheduled_sync)}") unless syncing
          if Time.now > next_scheduled_sync
            self.next_scheduled_sync = next_scheduled_sync + 1.day
            browser_queue << AutomaticSyncMessage.new
          end

          sleep 10
        end
      end
    end

    WARNING_MESSAGE = "The QuickBooks synchronization tool is currently in beta. Please confirm that you have backed up your QuickBooks company file before continuing.\n\nHave you backed up your quickbooks data before performing this synchronization?"

    def display_warning_message
      message_box = MessageBox.new shell, (SWT::YES | SWT::NO)
      message_box.message = WARNING_MESSAGE
      return_val = message_box.open

      exit unless return_val == SWT::YES
    end

    def initialize(options)
      @options = options
      @browser_queue = Queue.new
      @display = Display.get_default
      @shell = Shell.new(display)
    end

    def build_resolutions(resolutions)
      resolutions.map do |type, id, attributes|
        QuickBooksSync::Resolution.new [type, id], attributes
      end
    end

    class UILogger
      def initialize(ui)
        @ui = ui
      end
      attr_reader :ui

      def update(status)
        ui.update_status status
      end
    end

    def update_status(status)
      p ["status", status]
      browser_queue << StatusMessage.new(status)
    end

    def do_sync(resolutions = [])
      begin
        self.syncing = true
        show_spinner
        do_sync_without_error_handling resolutions
      rescue Exception => e
        error = [e.message] + e.backtrace
        self.html = error.map {|l| ERB::Util.h(l) + "<br />"}.join("\n")
      ensure
        self.syncing = false
      end
    end

    def do_sync_without_error_handling(resolutions=[])
      logger = UILogger.new(self)

      Exceptional.rescue_and_reraise do
        resolutions = build_resolutions(resolutions)
        qb = QuickBooksSync::Repository::QuickBooks.
          with_connection(QuickBooksSync::Connection.new, logger)

        repo = load_repository

        begin
          session = QuickBooksSync::Session.sync(qb, repo, resolutions || [], logger)
          render_status(session.conflicts, session.errors.values, session.remote_errors)
        rescue QuickBooksSync::VersionMismatch => e
          render_version_mismatch(e)
        rescue QuickBooksSync::UnknownServerError => e
          render_unknown_server_error(e)
        rescue Errno::ECONNREFUSED => e
          render_unknown_server_error(e)
        rescue Exception => e
          if e.to_s.include?("Could not start QuickBooks")
            render_quickbooks_not_started_error(e)
          else 
            raise e
          end
        rescue
          render_unknown_server_error($!)
        end

      end
    end

    def render_status(conflicts, local_errors, remote_errors)
      message = [ conflicts, local_errors, remote_errors ].all?(&:empty?) ?
        "Success!" : 
        "Errors and/or conflicts detected."
      status conflicts, local_errors, remote_errors, message
    end

    def render_version_mismatch(error)
      browser_queue << UpgradeMessage.new(error)
    end

    def render_unknown_server_error(error)
      browser_queue << UnknownServerMessage.new(error)
    end

    def render_quickbooks_not_started_error(error)
      browser_queue << QuickBooksNotStartedMessage.new(error)
    end

    def status(conflicts=[], local_errors=[], remote_errors=[], status=nil)
      self.html = erb("sync.html.erb", :locals => {
        :conflicts     => conflicts,
        :local_errors  => local_errors,
        :remote_errors => remote_errors,
        :status        => status
      })
    end

    def show_spinner
      self.html = erb("spinner.html.erb", :locals => {})
    end

    def hide_spinner
      self.browser.execute("$('.spinner').hide()")
    end

    def load_repository
      uri = URI.parse options[:remote]
      QuickBooksSync::Repository::Remote.new :host => uri.host,
        :port => uri.port,
        :ssl => uri.scheme == "https",
        :version => options[:version]
    end

    class HtmlMessage
      def initialize(text)
        @text = text
      end
      attr_reader :text

      def execute(ui)
        ui.browser.set_text text
      end
    end

    class StatusMessage
      def initialize(status)
        @status = status
      end
      attr_reader :status

      def execute(ui)
        ui.browser.execute("$('#status').text(#{status.to_json});")
      end
    end

    class UpgradeMessage
      include Swt
      include Swt::Widgets

      def initialize(error)
        @error = error
      end
      attr_reader :error

      VERSION_MISMATCH_MESSAGE = "Your QuickBooks-sync client is out of date.  Would you like to download a new version?"
      def execute(ui)
        ui.hide_spinner
        ui.browser.execute("$('#status').text('Version mismatch detected!');")

        message_box = MessageBox.new ui.shell, (SWT::YES | SWT::NO)
        message_box.message = VERSION_MISMATCH_MESSAGE
        return_val = message_box.open

        if return_val == SWT::YES
          Thread.new { `rundll32 url.dll,FileProtocolHandler #{error.client_download_url}` }
          sleep 1
          exit
        end
      end
    end

    class UnknownServerMessage 
      include Swt
      include Swt::Widgets

      def initialize(error)
        @error = error
      end
      attr_reader :error

      MESSAGE = "The remote server is not responding. Please contact your administrator."
      def execute(ui)
        ui.hide_spinner
        ui.browser.execute("$('#status').text('Remote server not responding');")

        message_box = MessageBox.new ui.shell, SWT::OK
        message_box.message = MESSAGE
      end
    end

    class QuickBooksNotStartedMessage 
      include Swt
      include Swt::Widgets

      def initialize(error)
        @error = error
      end
      attr_reader :error

      MESSAGE = "It doesn't look like QuickBooks is open. Please ensure you've started QuickBooks and opened your company file before proceeding."
      def execute(ui)
        ui.hide_spinner
        ui.browser.execute("$('#status').text('QuickBooks not started');")

        message_box = MessageBox.new ui.shell, SWT::OK
        message_box.message = MESSAGE
      end
    end

    class AutomaticSyncMessage
      def execute(ui)
        Thread.new { ui.do_sync([]) }
      end
    end

    def html=(html)
      browser_queue << HtmlMessage.new(html)
      display.wake
    end

    class SyncCallback < org.eclipse.swt.browser.BrowserFunction
      def initialize(browser, app)
        @app, @browser = app, browser
        super browser, "quickBooksSync"
      end

      def function(args)
        resolutions = JSON.parse(args.first.to_s)
        Thread.new do
          app.do_sync(resolutions)
        end

      end

      attr_reader :app, :browser

    end
  end
end
