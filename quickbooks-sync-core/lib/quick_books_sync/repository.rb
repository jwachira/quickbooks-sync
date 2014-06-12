require 'set'

module QuickBooksSync
  class Repository
    extend Memoizable

    def [](id)
      resources.by_id[id]
    end

    def valid?
      resources.all?(&:valid?)
    end

    def errors
      resources.reject(&:valid?).map(&:errors)
    end

    def split_dependencies(resources)
      if resources.empty?
        []
      else
        dependencies = resources.inject(Set.new) {|_, resource| _ + resource.dependencies}
        independent = resources.reject {|r| dependencies.include? r}.to_a
        split_dependencies(dependencies) + [independent]
      end
    end

    def resource_groups(resources)
      split_dependencies(resources).map {|g| g.reject(&:added?) }.reject(&:empty?)
    end

    def client_download_url; end

    def log(message)
      # no-op
    end

  end
end
