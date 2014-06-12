module QuickBooksSync
  class Repository
    class QuickBooks < Repository

      delegate :correct_for_daylight_savings_time?, :to => :client

      def initialize(client, logger = StubLogger.new)
        @client, @logger = client, logger
      end

      attr_reader :client, :logger

      def self.with_connection(connection, logger = StubLogger.new)
        new(QuickBooksSync::Client.new(connection), logger)
      end

      class ChangeResponse
        def initialize(response, client)
          @response, @client = response, client
        end

        attr_reader :response, :client

        def metadata
          if resource
            resource.metadata
          else
            { :quick_books_id => '' }
          end
        end

        delegate :error?, :message, :to => :response

        def resource
          elements = response.resource_elements
          return nil if elements.size == 0
          raise "operation should return one and only one resource:\n#{elements.inspect}" if elements.length > 1
          @resource ||= Resource.from_xml(elements.first, client)
        end
      end

      def add(original_resources)
        updated_metadata = {}

        unadded_resources = original_resources.reject(&:added?)

        resource_groups(unadded_resources).each do |resources|

          client.request(:on_error => :continue) do |r|
            resources.each do |resource|

              r.add(resource.type, resource.to_xml(:add, updated_metadata)) do |response|
                updated_metadata[resource.id] = ChangeResponse.new(response, client)
              end
            end
          end

        end

        expire_resources!
        updated_metadata
      end

      def update(resources)
        metadata_by_id = {}

        client.request(:on_error => :continue) do |r|
          resources.each do |resource|

            r.modify(resource) do |response|
              metadata_by_id[resource.id] = ChangeResponse.new(response, client)
            end
          end
        end

        expire_resources!
        metadata_by_id
      end

      def delete(ids)
        client.request(:on_error => :continue) do |r|
          ids.each do |id|
            r.delete id
          end
        end

        expire_resources!
      end

      def resources
        ResourceSet.from_enumerator(enum_for(:each_resource))
      end
      memoize :resources

      private

      def expire_resources!
        expire_memoized :resources
      end

      MAX_PER_PAGE = 500

      def each_resource
        i = 0
        client.request do |r|

          Resource.top_level_subclasses.select(&:queryable_from_quickbooks?).each do |klass|

            xml = "<MaxReturned>#{MAX_PER_PAGE}</MaxReturned>" + if klass.include_line_items?
              "<IncludeLineItems>1</IncludeLineItems>"
            else
              ""
            end

            options = if klass.iterator?
              {:iterator => "Start"}
            else
              {}
            end

            r.query(klass.type, xml, options) do |response|
              logger.update "Fetching QuickBooks resources...(#{i} fetched)"

              response.raise_if_error!

              response.resource_elements.each do |xml|
                i += 1
                yield Resource.from_xml(xml, client)
              end
            end
          end
        end
      end

      def empty?
        false
      end

    end
  end
end
