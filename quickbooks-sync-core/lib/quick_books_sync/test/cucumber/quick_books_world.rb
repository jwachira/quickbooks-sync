module QuickBooksSync
  module Test
    module Cucumber

      def wait_for_sync_server
        not_responding = true
        while not_responding
          begin
            @sync_server.resources
            not_responding = false
          rescue Errno::ECONNREFUSED => e
            not_responding = true
          end
        end
      end

      def resource_matches(resources, type, attributes={}, metadata={})
        resources.select do |r|
          r.type == type.to_sym &&
            attributes.select {|k, v| r.attributes[k] != v}.empty? &&
            metadata.select {|k, v| r.metadata[k] != v}.empty?
        end
      end

      TIME_KEYS = [:created_at, :updated_at]
      METADATA_KEYS = [:quick_books_id, :vector_clock]
      def extract_data(hash)
        times = TIME_KEYS.inject({}) do |_, k|
          if hash.include?(k.to_s)
            _.merge k => Time.parse(hash.delete(k.to_s))
          else
            _
          end
        end

        metadata = METADATA_KEYS.inject({}) do |_, k|
          _.merge k => hash.delete(k.to_s)
        end.reject {|k,v| v.nil?}.merge(times)

        type = hash.delete('type') || raise("no type specified!")

        [type, hash, metadata]
      end

      class QuickBooksWorld
        include QuickBooksSync::Test
        include QuickBooksSync::Test::Cucumber
      end

    end
  end
end
