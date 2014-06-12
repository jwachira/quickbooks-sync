require 'digest/sha1'
require 'time'

module QuickBooksSync

  class Resource
    extend Memoizable

    def initialize(raw_attributes, metadata, other_resources={})
      @raw_attributes, @metadata, @other_resources = raw_attributes, metadata, other_resources
    end

    attr_reader :raw_attributes, :metadata, :other_resources

    class Reference
      def initialize(target_type, target_id)
        @target_type, @target_id = target_type, target_id
      end
      attr_reader :target_type, :target_id

      def ==(other)
        target_type == other.target_type and target_id == other.target_id
      end

      def resolve(others)
        others[full_id]
      end

      def full_id
        [target_type, target_id]
      end
    end


    class RawReference < Reference
      def initialize(resource)
        @resource = resource
      end
      attr_reader :resource

      def resolve(others)
        resource
      end

      def target_id
        resource and resource.unique_id
      end
    end

    class << self
      def extra_fields(fields)
        eigenclass = class << self; self; end

        eigenclass.class_eval {
          define_method(:fields_by_name_with_extras) do
            fields_by_name_without_extras.merge(fields)
          end

          alias :fields_by_name_without_extras :fields_by_name
          alias :fields_by_name :fields_by_name_with_extras
        }
      end

      def of_type(type)
        const_get type
      end

      def fields
        @fields ||= field_names.map {|name| field(name) }
      end

      def field(name)
        fields_by_name[name]
      end

      def serialize_metadata(metadata)
        TIME_FIELDS.inject(metadata) do |_, key|
          if _.has_key?(key)
            _.merge key => _[key].to_i
          else
            _
          end
        end

      end

      def deserialize_metadata(metadata)
        TIME_FIELDS.inject(metadata) do |_, key|
          if _.has_key?(key)
            _.merge key => Time.at(_[key])
          else
            _
          end
        end
      end

      def subclasses
        constants.sort.map {|name| const_get(name) }.select {|klass| klass.is_a?(Class) and klass < self }
      end

      def top_level_subclasses
        subclasses.select(&:top_level?)
      end

      def iterator?
        true
      end

      def modable?
        true
      end

      def addable_to_remote?
        true
      end
      
      def modable_on_remote?
        true
      end

      def queryable_from_quickbooks?
        top_level?
      end

      def concrete_superclass
        @concrete_superclass ||= begin
          ([self] + superclasses).detect {|klass| klass.nested? or klass.top_level? }
        end
      end


      def superclasses
        if superclass.respond_to?(:superclasses)
          [superclass] + superclass.superclasses
        else
          []
        end
      end

      def from_xml(xml, client)
        Resource::XmlReader.new(xml, client).to_resource
      end

      def from_json(type, attributes, metadata)
        Resource::JsonReader.new(type, attributes, metadata).to_resource
      end

      def from_raw(type, data, metadata)
        data = data.inject({}) do |_, (k, v)|
          _.merge k.to_sym => if v.is_a?(Resource)
            Resource::RawReference.new(v)
          else
            v
          end
        end

        Resource.of_type(type).new data, metadata

      end

    end

    delegate :key_name,
             :field_names,
             :type,
             :top_level?,
             :nested?,
             :modable_on_quickbooks?,
             :modable_on_remote?,
             :concrete_superclass,
             :field_names,
             :modable?,
             :addable_to_remote?,
             :queryable_from_quickbooks?,
             :to => :"self.class"

    def inspect
      "#<#{type}: #{serialized_attributes.inspect} #{metadata.inspect}>"
    end

    def field_classes
      self.class.fields
    end

    def fields
      field_classes.map {|klass| klass.new(self) }
    end

    def fields_by_name
      fields.to_hash_keyed_by(&:name)
    end
    memoize :fields_by_name

    def field(name)
      fields_by_name[name]
    end

    METADATA_FIELDS = [:quick_books_id, :created_at, :updated_at, :vector_clock, :deleted, :local_id, :changed_since_sync]

    def self.metadata_from_object(object)
      METADATA_FIELDS.inject({}) do |_, key|
        if object.respond_to?(key)
          _.merge key => object.send(key)
        else
          _
        end
      end.reject {|k, v| v.nil?}
    end

    METADATA_FIELDS.each do |name|
      define_method(name) do
        metadata[name]
      end
    end

    alias :deleted? :deleted


    def references
      fields.select {|f| f.reference? or f.unwrapped_reference? }
    end

    def [](key)
      value_for_field(field(key.to_sym))
    end

    def nested_fields
      fields.select &:nested?
    end

    def attributes
      raw_attributes
    end

    def value_for_field(field)
      field.value if field
    end


    def dependencies
      dependencies_and_nested.reject(&:nested?)
    end

    def dependencies_and_nested
      (references.map {|f| value_for_field(f) } + nested_fields.map { |f| value_for_field(f) }.flatten).compact.
        map {|resource| [resource] + resource.dependencies }.flatten
    end

    def direct_dependencies
      references.map(&:value) + dependencies_from_nested
    end

    def dependencies_from_nested
      nested_fields.map(&:value).flatten.map {|resource| resource.direct_dependencies}.flatten
    end

    def changed_since_sync?
      !!changed_since_sync
    end

    def last_modified
      updated_at || created_at || Time.at(0)
    end

    def id
      [concrete_superclass.type, unique_id]
    end

    def unique_id
      (quick_books_id || local_id) unless nested?
    end

    def with_other_resources(others)
      updated_attributes = fields.select(&:nested?).inject(raw_attributes) do |_, field|
        _.merge field.name => (raw_attributes[field.name] || []).map {|nested| nested.with_other_resources(others) }
      end

      self.class.new updated_attributes, metadata, others
    end

    def dup
      self.class.new attributes, metadata, other_resources
    end

    def with_updated_metadata(updated_metadata)
      self.class.new attributes, updated_metadata, other_resources
    end

    def with_merged_metadata(merged)
      with_updated_metadata metadata.merge(merged)
    end

    def added?
      !!quick_books_id
    end

    def ==(other)
      return false unless other
      return false unless other.is_a?(QuickBooksSync::Resource)
      common_keys = self.serialized_attributes.keys.to_set & other.serialized_attributes.keys.to_set

      self.id == other.id and common_keys.all? {|k| self.serialized_attributes[k] == other.serialized_attributes[k] }
    end

    alias :eql? :==

    delegate :hash, :to => :id

    def valid?
      errors.empty?
    end

    delegate :to_json, :to => :serialized

    def field_cache
      @field_cache ||= {}
    end


    def serialized
      [ self.type,
        serialized_attributes,
        serialized_metadata]
    end

    def serialized_attributes
      fields.to_hash_keyed_by_with_values do |field|
        [field.name, field.serialized_value]
      end.reject {|k, v| v.nil? }
    end

    def to_xml(operation, updated_metadata={})
      builder do |x|
        x.tag!("#{type}#{operation.to_s.capitalize}") do
          if operation == :mod
            x << xml_id
            x << xml_vector_clock
          end
          x << xml_attributes(operation, updated_metadata)
        end
      end
    end

    def xml_attributes(operation, updated_metadata)
      builder do |x|
        fields.select {|f| f.defined? and !f.unchangeable_on_quickbooks?}.each do |field|
          x << field.to_xml(operation, updated_metadata)
        end
      end
    end

    def xml_id
      builder do |x|
        x.tag!(key_name) { x.text!(quick_books_id) }
      end
    end

    def xml_vector_clock
      builder {|x| x.EditSequence(vector_clock)}
    end

    def errors
      fields.map {|field| [field, field.error]}.select {|field, error| error}.inject({}) do |_, (field, error)|
        _.merge field.name => error
      end
    end

    def serialized_metadata
      Resource.serialize_metadata(metadata)
    end

    attr_reader :raw_attributes
    private

    include QuickBooksSync::XmlBuilder

    def stringize_keys(hash)
      hash.inject({}) do |_, (k, v)|
        _.merge k.to_s => v
      end
    end


    TIME_FIELDS = [:created_at, :updated_at]

  end
end
