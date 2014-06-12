require 'json'

module QuickBooksSync
  class Repository
    class Local < Repository

      def initialize(resources)
        self.resources = resources
      end

      def resources
        QuickBooksSync::ResourceSet.new(@resources.map(&:dup))
      end

      def resources=(other)
        @resources = QuickBooksSync::ResourceSet.new(other.map(&:dup))
      end

      def add(resources)
        self.resources += resources
      end

      def update(other_resources)
        by_id = other_resources.by_id

        self.resources = resources.map do |resource|
          if by_id.include?(resource.id)
            by_id[resource.id]
          else
            resource
          end
        end
      end

      def update_ids(new_ids_by_local_ids)
        new_ids_by_local_ids.each do |local_id, new_id|
          resources.by_id[local_id].quick_books_id = new_id
        end
      end

      def update_metadata(all_metadata)
        self.resources = resources.map do |resource|
          if metadata = all_metadata[resource.id]
            resource.with_merged_metadata(metadata)
          else
            resource
          end
        end

      end

      def delete(ids)
        self.resources = resources.reject {|resource| ids.include? resource.id }
      end

      def mark_as_synced
        self.resources = resources.map do |resource|
          resource.with_updated_metadata resource.metadata.merge(:changed_since_sync => false)
        end
        true
      end

      private


    end
  end
end
