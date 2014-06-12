module QuickBooksSync
  class Resolution
    attr_reader :attributes, :id
    def initialize(id, attributes)
      type, qb_id = id
      @id, @attributes = [type.to_sym, qb_id], attributes
    end

    def merge(resource)
      resource.class.new(
        resource.attributes.merge(self.attributes),
        resource.metadata
      )
    end

  end
end