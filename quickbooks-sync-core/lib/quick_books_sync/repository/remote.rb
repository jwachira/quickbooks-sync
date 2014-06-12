require 'httparty'

module QuickBooksSync
  class VersionMismatch < Exception
    def initialize(client_download_url = nil)
      @client_download_url = client_download_url
    end

    attr_reader :client_download_url
  end
  class ServerError < Exception; end
  class UnknownServerError < Exception; end

  class Repository::Remote < QuickBooksSync::Repository
    extend Memoizable
    ROOT = "/resources"
    include QuickBooksSync

    VERSION_HEADER = "X_CLETUS_VERSION"

    def initialize(options)
      @connection = Connection.new(options)
    end

    attr_reader :connection

    def add(resources)
      json = to_resource_set(resources).to_packaged
      JSON.parse(connection.post(ROOT, json)).map {|e| Error.from_serialized(e) }
    end

    def update(resources)
      return if resources.empty?
      connection.put(ROOT, to_resource_set(resources).to_packaged)
    end

    def delete(ids)
      return if ids.empty?
      connection.put("#{ROOT}/delete", ids.to_a.to_json)
    end

    def update_ids(new_ids_by_local_ids)
      return if new_ids_by_local_ids.empty?
      json = new_ids_by_local_ids.map {|old_id, new_id| { 'old_id' => old_id, 'new_id' => new_id } }.to_packaged
      connection.put("#{ROOT}/ids", json)
    end

    def update_metadata(metadata)
      return if metadata.empty?
      json = metadata.map {|k ,v| { 'id' => k, 'metadata' => Resource.serialize_metadata(v) } }.to_json
      connection.put("#{ROOT}/metadata", json)
    end

    def mark_as_synced
      connection.put("#{ROOT}/synced", "true")
    end

    def log(msg)
      begin
        connection.post "#{ROOT}/log", msg
      rescue Exception => e
        $stderr.puts "Exception while logging: #{e.inspect}"
      end
    end

    def resources
      ResourceSet.from_packaged_string connection.get(ROOT)
    end

    def to_resource_set(set)
      if set.is_a?(ResourceSet)
        set
      else
        ResourceSet.new(set)
      end
    end

    class Connection
      def initialize(options)
        @host = options[:host] || 'localhost'
        @port = options[:port] || 4567
        @ssl  = options[:ssl]  || false
        @version = options[:version] || raise("must specify a :version")
        @certificate = options[:certificate]
      end

      attr_reader :host, :port, :ssl, :certificate, :version

      HTTP_METHODS = [:get, :post, :put, :delete]
      HTTP_METHODS.each do |method|
        define_method(method) do |path, *args|
          payload = args.first
          execute method, path, payload
        end
      end

      def client
        base = "#{ssl ? "https" : "http"}://#{host}:#{port}"
        Class.new do
          include HTTParty
          base_uri base
        end
      end

      def execute(method, path, payload)
        response = client.send(method, path,
          :headers => headers(method, path, payload),
          :body => payload,
          :timeout => TIMEOUT
        )

        check_for_errors(response)
        response.body
      end

      def check_for_errors(response)
        status = response.code.to_i

        error(status, response.body) if status != 200
      end

      def error(status, body)
        data = JSON.parse(body) rescue nil

        raise UnknownServerError.new unless data

        if status == 403
          if data['status'] == QuickBooksSync::Server::VERSION_MISMATCH and data['client_download_url']
            raise VersionMismatch.new(data['client_download_url'])
          else
            raise UnknownServerError.new
          end
        else
          exception = ServerError.new(data['error'])
          exception.set_backtrace(data['backtrace'])

          raise exception
        end
      end

      TIMEOUT = 60 * 5

      private

      def headers(method, url, payload)
        {HttpAuthenticator::SIGNATURE_HEADER =>
          HttpAuthenticator.signature(method, url, payload),
         VERSION_HEADER => version
        }
      end

      def scheme
        @ssl ? 'https' : 'http'
      end

      def base_url
        "#{scheme}://#{host}:#{port}"
      end
    end


  end

end
