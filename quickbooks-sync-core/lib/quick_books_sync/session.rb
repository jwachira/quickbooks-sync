module QuickBooksSync

  class Session

    attr_reader :quickbooks_repository,
                :remote_repository,
                :resolutions,
                :logger

    def self.sync(qb, remote, resolutions=[], logger=nil)
      Session.new(qb, remote, resolutions, logger).sync
    end

    def initialize(quickbooks_repository, remote_repository, resolutions, logger)
      @quickbooks_repository  = quickbooks_repository
      @remote_repository = remote_repository
      @resolutions = resolutions

      @logger = logger || StubLogger.new
    end
    extend Memoizable

    def remote_resources
      log "Fetching remote resources..."
      remote_repository.resources
    end
    memoize :remote_resources

    def quickbooks_resources
      log "Fetching QuickBooks resources..."
      quickbooks_repository.resources
    end
    memoize :quickbooks_resources

    def metadata_from_add
      log "Determining resources to add to QuickBooks..."
      unless resources_to_add_to_quickbooks.empty?
        log "Adding #{resources_to_add_to_quickbooks.length} resources to QuickBooks..."
        quickbooks_repository.add resources_to_add_to_quickbooks
      else
        {}
      end
    end
    memoize :metadata_from_add

    def metadata_from_update
      log "Determining resources to update on QuickBooks..."
      update_metadata = unless resources_to_update_on_quickbooks.empty?
        log "Updating #{resources_to_update_on_quickbooks.length} QuickBooks resources..."

        quickbooks_repository.update resources_to_update_on_quickbooks
      else
        {}
      end
    end
    memoize :metadata_from_update

    def add_to_remote
      unless resources_to_add_to_remote.empty?
        log "Adding #{resources_to_add_to_remote.length} resources to remote repository..."
        remote_repository.add resources_to_add_to_remote
      else
        []
      end
    end
    memoize :add_to_remote

    def remote_errors
      add_to_remote
    end

    def merged_metadata
      log "Merging QuickBooks metadata..."
      metadata_from_add.merge(metadata_from_update)
    end

    def partition_metadata
      failed_updated_metadata, successfully_updated_metadata = merged_metadata.partition do |k ,v|
        v.error?
      end.map(&:to_hash_keyed_by_with_values)
    end

    def failed_updated_metadata
      partition_metadata.first
    end

    def successfully_updated_metadata
      partition_metadata.last
    end

    def sync
      log "Beginning sync process..."
      # let's prewarm these so status messages make sense
      remote_resources
      quickbooks_resources

      # PRELOADER!
      metadata_from_add
      metadata_from_update

      dev_log "Failed to update the following resources:\n#{failed_updated_metadata.inspect}"

      log "Updating remote repository metadata..."
      metadata_from_update = successfully_updated_metadata.to_hash_keyed_by_with_values do |k, v|
        [k, v.metadata]
      end
      remote_repository.update_metadata metadata_from_update

      dev_log "Failed to add the following resources to the EMS: #{add_to_remote.inspect}"

      resources_to_update_on_remote_with_updated_metadata = merge_resources_with_metadata(resources_to_update_on_remote, successfully_updated_metadata)

      unless resources_to_update_on_remote_with_updated_metadata.empty?
        log "Updating #{resources_to_update_on_remote_with_updated_metadata.length} resources on remote repository..."
        remote_repository.update resources_to_update_on_remote_with_updated_metadata
      end

      log "Determining unused QuickBooks IDs..."
      unless ids_to_delete_from_quickbooks.empty?
        log "Deleting from QuickBooks..."
        quickbooks_repository.delete ids_to_delete_from_quickbooks
        remote_repository.delete ids_to_delete_from_quickbooks
      end

      log "Determining unused remote IDs..."
      unless ids_to_delete_from_remote.empty?
        log "Deleting from remote (#{ids_to_delete_from_remote.size})..."
        remote_repository.delete ids_to_delete_from_remote
      end

      log "Mark remote repository as synced..."
      remote_repository.mark_as_synced if conflicts.empty?

      self
    end

    def errors
      failed_updated_metadata
    end

    def conflicts
      partitioned_conflicts.last
    end

    private

    def merge_resources_with_metadata(resources, all_metadata)
      ResourceSet.new(resources.map do |resource|
        if response = all_metadata[resource.id]
          resource.with_updated_metadata response.metadata
        else
          resource
        end
      end)
    end

    def possible_conflicts
      conflicts_and_accepted.first
    end
    memoize :possible_conflicts

    def id_set(resources)
      resources.map(&:id).to_set
    end

    def ids_to_delete_from_remote
      id_set(remote_resources.select {|r| r.added? and r.queryable_from_quickbooks?}) - id_set(quickbooks_resources)
    end
    memoize :ids_to_delete_from_remote

    def ids_to_delete_from_quickbooks
      remote_resources.select(&:deleted?).map(&:id)
    end
    memoize :ids_to_delete_from_quickbooks

    def resources_to_add_to_remote
      log "Determining resources to add to remote repository..."
      quickbooks_resources.not_present_in(remote_resources).select(&:addable_to_remote?)
    end
    memoize :resources_to_add_to_remote

    def resources_to_add_to_quickbooks
      remote_resources.not_yet_added
    end
    memoize :resources_to_add_to_quickbooks

    def resources_to_update_on_quickbooks
      remote_winners + merged_resolutions
    end
    memoize :resources_to_update_on_quickbooks

    def conflicts_and_accepted
      remote_resources.reject do |resource|
        ids_to_delete_from_remote.include? resource.id
      end.partition_conflicts(quickbooks_resources)
    end
    memoize :conflicts_and_accepted

    def resolved_conflicts
      partitioned_conflicts.first
    end

    def partitioned_conflicts
      possible_conflicts.partition do |conflict|
        resolutions_by_id.has_key? conflict.id
      end
    end
    memoize :partitioned_conflicts

    def merged_resolutions
      resolutions.map do |resolution|
        conflicted_resources = quickbooks_resources.by_id[resolution.id]
        resolution.merge conflicted_resources
      end
    end
    memoize :merged_resolutions

    # ====

    def remote_winners
      remote_and_quickbooks_winners.first
    end

    def quickbooks_winners
      remote_and_quickbooks_winners.last
    end

    def resources_to_update_on_remote
      (quickbooks_winners + merged_resolutions).select(&:modable_on_remote?)
    end
    memoize :resources_to_update_on_remote

    def remote_and_quickbooks_winners
      accepted.partition_winners
    end
    memoize :remote_and_quickbooks_winners

    def accepted
      conflicts_and_accepted.last
    end

    # ====

    def resolutions_by_id
      resolutions.to_hash_keyed_by(&:id)
    end

    # Log to both the status box of the UI as well as the remote server.
    def log(message)
      logger.update message
      dev_log(message)
    end

    # Only log messages to the remote server for distribution via e-mail digest
    # to team.
    def dev_log(message)
      remote_repository.log(message) if remote_repository.respond_to?(:log)
    end

  end

end
