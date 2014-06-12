module QuickBooksSync
  class Error
    def initialize(resource, error)
      @resource, @error = resource, error 
    end

    def message
      "#{error.first.gsub('_', ' ').capitalize} #{error.last}"
    end

    def self.from_serialized(attributes)
      new(
        Resource.from_json(*attributes['resource']),
        attributes['error']
      )
    end

    def serialized
      {
        'message'  => message,
        'resource' => resource,
        'error'    => error
      }
    end

    delegate :to_json, :to => :serialized

    attr_reader :error, :resource
  end

end
