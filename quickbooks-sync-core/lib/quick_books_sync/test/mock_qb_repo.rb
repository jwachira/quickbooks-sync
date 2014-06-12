module QuickBooksSync
  module Test

    class MockChangeResponse
      def initialize(resource)
        @resource = resource
      end

      attr_reader :resource

      delegate :metadata, :to => :resource

      def error?
        false
      end
    end

    class MockQBRepo < QuickBooksSync::Repository::Local
      attr_reader :resources_by_id
      def initialize(resources)
        @resources_by_id = {}
        self.add resources
      end

      def add(resources)
        resources.inject({}) do |_, resource|
          old_id = resource.id
          resource = if resource.quick_books_id
            resource
          else
            resource.with_merged_metadata(:quick_books_id => unique_id)
          end

          raise "adding resource that already exists" if resources_by_id.include?(resource.id)
          self.resources_by_id[resource.id] = resource

          _.merge old_id => MockChangeResponse.new(resource)
        end
      end

      def update(resources)
        resources.inject({}) do |_, resource|
          updated = resource.with_merged_metadata(:vector_clock => (resource.vector_clock.to_i + 1).to_s)
          self.resources_by_id[updated.id] = updated

          _.merge resource.id => MockChangeResponse.new(updated)
        end
      end

      def delete(ids)
        ids.each do |id|
          resources_by_id.delete id
        end

      end

      def unique_id
        @i ||= 0
        (@i += 1).to_s
      end

      def resources
        QuickBooksSync::ResourceSet.new(resources_by_id.values)
      end

    end
  end
end
