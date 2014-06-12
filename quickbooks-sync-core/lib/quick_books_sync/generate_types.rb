module QuickBooksSync
  class ClassGenerator
    class << self
      def generate(mod)
        new(QuickBooksSync::Resource::TYPES).generate(mod)
      end
    end

    def initialize(types)
      @types = types
    end

    def generate(mod)
      types.each do |name, data|
        mod.const_set(name, type_from_name(name))
      end
    end

    def type_from_name(name)
      generated_types[name] ||= make_class(name, types[name])
    end

    private

    def make_class(name, data)
      superclass = if superclass_name = superclasses[name]
        type_from_name(superclass_name)
      end

      k = Class.new(superclass || QuickBooksSync::Resource)

      fields_by_name = build_fields_by_name(data)

      define_fields_on_class(k,
        :abstract? => data[:abstract],
        :top_level? => (data[:abstract] or (data[:top_level] and !superclass)),
        :nested? => (!data[:top_level] and !superclass and !data[:concrete_subtypes]),
        :include_line_items? => data[:include_line_items],
        :modable_on_quickbooks? => data[:modable],
        :fields_by_name => fields_by_name,
        :field_names => fields_by_name.keys,
        :key_name => data[:key_name],
        :type => name.to_sym,
        :inspect => name
      )

      k
    end

    def self.define(k, method_name, &block)
      k.instance_eval { define_method(method_name, &block) }
    end

    def build_fields_by_name(data)
      (data[:fields] || {}).map do |metadata|
        field_from_metadata(metadata)
      end.to_hash_keyed_by(&:name)
    end

    def self.field_from_metadata(metadata)
      klass = Class.new(QuickBooksSync::Field)
      type = metadata[:type]

      target = metadata[:target].to_sym if metadata[:target]

      fields = [:element_name, :type, :max_length, :choices].inject({}) do |_, key|
        _.merge key => metadata[key]
      end.merge(
        :unwrapped_reference? => (type == :unwrapped_ref),
        :reference? => (type == :ref),
        :sum? => (type == :sum),
        :serialize? => (type != :sum),
        :enum? => (type == :enum),
        :nested? => (type == :nested),
        :target_type => target,
        :name => metadata[:name].to_sym,
        :unchangeable_on_quickbooks? => !!metadata[:unchangeable_on_quickbooks]
      )

      define_fields_on_class klass, fields

      klass
    end

    def self.define_on_class(k, method_name, &block)
      metaclass = class << k; self; end
      define metaclass, method_name, &block
    end

    def self.define_fields_on_class(klass, fields={})
      fields.each do |key, val|
        define_on_class(klass, key) { val }
      end
    end

    delegate :field_from_metadata, :define_fields_on_class, :to => :"self.class"

    def abstract_types
      types.select {|k, t| t[:abstract] }
    end

    def superclasses
      abstract_types.inject({}) do |_, (name, type)|
        type[:concrete_subtypes].inject(_) do |__, subtype|
          __.merge subtype => name
        end
      end
    end

    def generated_types
      @generated_types ||= {}
    end

    attr_reader :types

  end
end
