module QuickBooksSync
  module Server

    BAD_AUTHENTICATION_CODE = "bad_authentication_code"
    VERSION_MISMATCH = "version_mismatch"

    require 'sinatra/base'

    def self.create(options={})
      klass = Class.new(Application)
      klass.repository = options[:repository]
      klass.version = options[:version]

      klass
    end

    class Application < Sinatra::Base
      class << self
        attr_accessor :repository, :version
      end

      delegate :repository, :version, :to => :"self.class"

      ROOT = "/resources"

      def self.request(method, path, opts={}, &block)

        skip_version_verification = opts.delete(:skip_version_verification)

        route(method.to_s.upcase, path, opts) do
          payload = request.body.read
          signature = request.env["HTTP_" + HttpAuthenticator::SIGNATURE_HEADER]
          method = request.request_method.downcase
          path = request.path

          unless HttpAuthenticator.matches?(signature, method, path, payload)
            return unauthorized
          end

          remote_version = request.env["HTTP_" + QuickBooksSync::Repository::Remote::VERSION_HEADER]

          unless skip_version_verification or remote_version == version
            return version_mismatch(repository)
          end

          begin
            yield(repository, payload)
          rescue Exception => error
            halt(500, {"error" => error.to_s, "backtrace" => error.backtrace}.to_json)
          end
        end
      end

      def unauthorized
        halt 403, BAD_AUTHENTICATION_CODE
      end

      def version_mismatch(repository)
        data = {'status' => VERSION_MISMATCH, 'client_download_url' => repository.client_download_url}
        halt 403, data.to_json
      end

      request(:get, ROOT) do |repo, payload|
        repo.resources.to_packaged
      end

      request(:post, ROOT) do |repo, payload|
        resources = ResourceSet.from_packaged_string(payload)
        repo.add(resources).to_json
      end

      request(:put, ROOT) do |repo, payload|
        repo.update(ResourceSet.from_packaged_string(payload)).to_json
      end

      request(:put, "#{ROOT}/delete") do |repo, payload|
        repo.delete(JSON.parse(payload)).to_json
      end

      request(:put, "#{ROOT}/metadata") do |repo, payload|
        metadata = JSON.parse(payload).map do |item|
          [ item['id'], Resource.deserialize_metadata(item['metadata'].symbolize_keys) ]
        end
        repo.update_metadata(metadata).to_json
      end

      request(:put,"#{ROOT}/ids") do |repo, payload|
        ids = JSON.parse(payload).inject({}) {|_, item| _.merge(item['old_id'] => item['new_id']) }
        repo.update_ids(ids).to_json
      end

      request(:put, "#{ROOT}/synced") do |repo, payload|
        repo.mark_as_synced
        "true"
      end



      request(:post, "#{ROOT}/log", :skip_version_verification => true) do |repo, payload|
        if repo.respond_to?(:log)
          repo.log payload
        end
      end

    end

  end

end
