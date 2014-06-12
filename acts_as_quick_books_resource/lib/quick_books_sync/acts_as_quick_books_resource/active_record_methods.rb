module QuickBooksSync::ActsAsQuickBooksResource
  module ActiveRecordMethods
    def acts_as_quick_books_resource
      attr_accessor :changes_from_quick_books
      class_inheritable_accessor :quick_books_config
      delegate :quick_books_class, :to => :"self.class"
      include InstanceMethods

      self.quick_books_config = Configuration.new
      yield quick_books_config


      add_hooks if self.respond_to?(:before_save)
    end

    def add_hooks
      self.record_timestamps = false
      before_save do |instance|
        unless instance.updated_at_changed?
          instance.updated_at = Time.now
        end

        unless instance.new_record? or instance.changes_from_quick_books
          instance.changed_since_sync = true
        end

        instance.changes_from_quick_books = false
        nil
      end

      before_create do |instance|
        instance.created_at = Time.now
      end

    end

    delegate :top_level?, :to => :quick_books_class

    def include_on_find
      quick_books_config.associations_to_include_on_find || []
    end

    DEFAULT_METADATA_FIELDS = [:vector_clock, :created_at, :updated_at, :quick_books_id]
    def metadata_fields
      @metadata_fields ||= begin
        attribute_names = columns.map(&:name).map(&:to_sym)
        DEFAULT_METADATA_FIELDS.select {|field| attribute_names.include? field }
      end
    end

    # protected

    def quick_books_class
      Resource.of_type(quick_books_config.qb_name || self.name.demodulize)
    end

    module InstanceMethods
      def to_quick_books_resource
        QuickBooksSync::ActsAsQuickBooksResource::ActiveRecordReader.from_ar_instance(self)
      end
    end

    def acts_as_pennies(name)
      setter = :"#{name}="
      getter = name

      in_cents = "#{name}_in_cents"

      define_method(setter) do |val|
        self[in_cents] = QuickBooksSync::PennyConverter.to_pennies(val)
      end

      define_method(getter) do
        QuickBooksSync::PennyConverter.from_pennies(self[in_cents])

      end

    end

  end
end

module QuickBooksSync
  ActiveRecordMethods = ActsAsQuickBooksResource::ActiveRecordMethods
end