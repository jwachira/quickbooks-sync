module QuickBooksSync
  class Connection
     # There's a 36 character limit for this.  Learned the hard way.
    APP_NAME = "Turing Synchronization tool"

    DLL_PATH =  File.expand_path(File.dirname(__FILE__) + '/../jacob')
    JACOB_DLL_NAME = "jacob-1.15-M3-x86.dll"

    def self.library_path
      path = File.join(DLL_PATH, JACOB_DLL_NAME)

      if defined?(JarHelper) and JarHelper.in_jar? path
        JarHelper.extract_to_path File.join(DLL_PATH, JACOB_DLL_NAME), File.join(temp_path, JACOB_DLL_NAME), true
      else
        path
      end
    end

    def self.temp_path
      @temp_path ||= JarHelper.tmp_path
    end

    begin
      java.lang.System.setProperty("jacob.dll.path", library_path)
      require 'jacob/jacob.jar'
    rescue Exception => e

    end

    class ConnectionException < Exception
      def initialize(wrapped, xml)
        @wrapped, @xml = wrapped, xml
      end

      attr_reader :wrapped, :xml

      def message
        "exception (caused by #{wrapped.inspect}) caused by XML \n#{xml.inspect}"
      end

      alias :to_s :message
    end


    def request(xml)
      LOG.debug "sending #{xml.inspect}"

      response = begin
        with_manager do |manager|
          response_variant = dispatch.call(manager, "DoRequestsFromXMLString", xml)
          response_dispatch = response_variant.get_dispatch
          response_xml = dispatch.call(response_dispatch, "ToXMLString").to_s
          response_variant.safe_release
          response_dispatch.safe_release


          response_xml
        end
      rescue Exception => exception
        raise ConnectionException.new(exception, xml)
      end

      LOG.debug "got #{response.inspect}"

      response

    end

    def dispatch
      com.jacob.com.Dispatch
    end

    private

    def with_manager
      yield manager
    end

    def dont_care
      # Magic numbers!
      com.jacob.com.Variant.new(2)
    end

    def manager
      @manager ||= begin
        manager = dispatch.new "QBFC8.QBSessionManager"
        dispatch.call manager, "OpenConnection", "", APP_NAME
        dispatch.call manager, "BeginSession", "", dont_care

        at_exit { p "closing"; close }

        manager
      end
    end

    def close
      dispatch.call manager, "EndSession"
      dispatch.call manager, "CloseConnection"
      manager.safe_release
      @manager = nil
    end

    def correct_for_daylight_savings_time?
      Time.now.dst?
    end
  end

end
