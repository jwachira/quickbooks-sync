module QuickBooksSync::ActsAsQuickBooksResource
  Resource = QuickBooksSync::Resource
  class ActiveRecordReader

    def self.from_ar_instance(model)
      new(model).to_resource
    end

    def initialize(model)
      @model = model
    end

    def active_record?
      model.is_a?(ActiveRecord::Base)
    end

    def to_resource
      type_klass.new attributes, metadata
    end

    def fields_with_local_names
      @fields
    end

    def attributes
      type_klass.fields.map do |field|
        [field, config.attributes[field.name]]
      end.select do |field, local_name|
        local_name
      end.to_hash_keyed_by_with_values do |field, local_name|
        raw = model.send(local_name)

        value = if field.reference? or field.unwrapped_reference?
          if raw
            instance = ActiveRecordReader.from_ar_instance(raw)
            Resource::Reference.new(field.target_type, instance.quick_books_id || instance.local_id)
          end
        elsif field.nested?
          raw.map {|model| ActiveRecordReader.from_ar_instance(model) }
        else
          raw
        end


        [field.name, value]
      end
    end

    def type_klass
      model.class.quick_books_class
    end

    def metadata
      if active_record?
        active_record_metadata
      else
        {}
      end
    end

    def active_record_metadata
      [:quick_books_id, :vector_clock, :created_at, :updated_at, :changed_since_sync].select do |name|
        model.respond_to?(name)
      end.to_hash_keyed_by_with_values do |name|
        [name, model.send(name)]
      end.merge(:local_id => model.id.to_s).reject {|k, v| v.nil? }
    end

    def local_id
      model.id.to_s
    end

    private
    attr_reader :model

    def config
      model.class.quick_books_config
    end

    delegate :quick_books_id, :vector_clock, :created_at, :updated_at, :changed_since_sync, :to => :model

    alias :changed_since_sync? :changed_since_sync

  end
end