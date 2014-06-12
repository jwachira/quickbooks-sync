module QuickBooksSync::ActsAsQuickBooksResource
  class ActiveRecordWriter
    include QuickBooksSync::ActsAsQuickBooksResource
    def initialize(repository, resources)
      @repository, @resources = repository, resources
    end
    attr_reader :repository, :resources, :errors

    def models_by_id
      @models_by_id ||= {}
    end

    def to_model(resource)
      models_by_id[resource.id] ||= ActiveRecordGenerator.new(repository, resource, self).to_model
    end

    def save
      resources.each_slice(2000).map do |slice|
        ActiveRecord::Base.transaction do
          slice.map {|resource| save_resource(resource) }
        end
      end.flatten
    end

    protected

    def save_resource(resource)
      model = to_model(resource)
      if model.new_record?
        model.save
        model.errors.map {|e| Error.new(resource, e) }
      else
        []
      end
    end

  end
end
