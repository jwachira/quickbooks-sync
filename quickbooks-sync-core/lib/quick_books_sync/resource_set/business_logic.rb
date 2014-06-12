module QuickBooksSync
  class ResourceSet
    module BusinessLogic

      class AcceptedResourceSet
        def initialize(resources)
          @resources = resources
        end
        attr_reader :resources

        def partition_winners
          remote, quickbooks = resources.partition do |remote_resource, quickbooks_resource|
            quickbooks_resource && remote_resource && remote_resource.modable_on_quickbooks? &&
            remote_resource.last_modified.to_i > quickbooks_resource.last_modified.to_i
          end

          remote = remote.map {|r, q| r }
          quickbooks = quickbooks.map {|r, q| q }

          [ ResourceSet.new(remote), ResourceSet.new(quickbooks) ]
        end

      end

      def not_present_in(resources)
        reject do |resource|
          resources.by_id.include? resource.id
        end.map {|resource| resource}
      end

      def partition_conflicts(other_resources)
        conflicts, accepted = modified_from(other_resources).partition do |remote_resource, local_resource|
          local_resource &&
          remote_resource &&
          remote_resource.changed_since_sync? &&
          local_resource.vector_clock != remote_resource.vector_clock
        end

        conflicts = conflicts.map do |remote, local|
          Conflict.new(remote, local)
        end

        [ conflicts, AcceptedResourceSet.new(accepted) ]
      end


      def modified_from(other_resources)

        select do |resource|
          resource.added? and resource.modable?
        end.map do |resource|
          [resource, other_resources.by_id[resource.id]]
        end.select do |remote_resource, local_resource|
          remote_resource != local_resource
        end
      end

      def not_yet_added
        select {|resource| !resource.added? }
      end


    end
  end
end