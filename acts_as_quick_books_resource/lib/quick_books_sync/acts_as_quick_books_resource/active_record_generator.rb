module QuickBooksSync::ActsAsQuickBooksResource
  class ActiveRecordGenerator
    extend QuickBooksSync::Memoizable

    def initialize(repository, resource, writer)
      @repository, @resource, @writer = repository, resource, writer
    end

    def to_model
      ar_klass.new(attributes)
    end

    def attributes
      attributes_from_keys(quick_books_config.attributes)
    end

    def update_attributes
      attributes_from_keys(update_attributes_mapping)
    end

    def metadata
      ar_klass.metadata_fields.to_hash_keyed_by_with_values do |k|
        [k, resource.send(k)]
      end
    end

    def value(qb_key)
      field = field(qb_key)
      if field.reference? or field.unwrapped_reference?
        if referenced = field.value
          writer.to_model(referenced)
        end
      elsif field.nested?
        field.value.map do |nested|
          ActiveRecordGenerator.new(repository, nested, writer).to_model
        end
      else
        field.value
      end
    end

    def to_models
      [to_model, dependent_models]
    end

    attr_reader :repository, :resource, :writer

    def ar_klass
      repository.ar_class_from_resource_type(type)
    end

    memoize :ar_klass

    delegate :fields, :field, :type, :to => :resource
    delegate :quick_books_config, :to => :ar_klass

    private

    def attributes_from_keys(keys)
      keys.to_hash_keyed_by_with_values do |qb_key, ar_key|
        [ar_key, value(qb_key)]
      end.merge(metadata)
    end

    def update_attributes_mapping
      if restricted_to = quick_books_config.update_only_fields
        quick_books_config.attributes.reject {|k, v| !restricted_to.include?(k)}
      else
        quick_books_config.attributes
      end
    end

  end
end
