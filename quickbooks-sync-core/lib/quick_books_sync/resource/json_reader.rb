class QuickBooksSync::Resource::JsonReader
  include QuickBooksSync

  def initialize(type, raw_attributes, raw_metadata)
    @type = type
    @raw_attributes = symbolize_keys(raw_attributes)
    @raw_metadata = symbolize_keys(raw_metadata)
  end

  def to_resource
    Resource.of_type(type).new attributes, metadata
  end

  def attributes
    raw_attributes.map do |name, raw|
      field = type_klass.field(name)
      val = if field.reference? or field.unwrapped_reference?
        Resource::Reference.new(field.target_type, raw)
      elsif field.nested?
        (raw || []).map {|type, attributes, metadata| self.class.new(type, attributes, metadata).to_resource }
      else
        raw
      end

      [name, val]
    end.to_hash_keyed_by_with_values
  end

  def metadata_without_time
    Resource::METADATA_FIELDS.inject({}) do |_, name|
      _.merge name => raw_metadata[name]
    end
  end

  def metadata
    Resource::TIME_FIELDS.inject(symbolize_keys(raw_metadata)) do |_, name|
      _.merge name => parse_time_or_nil(_[name])
    end
  end

  def parse_time_or_nil(value)
    Time.at(value) if value
  end

  def type_klass
    Resource.of_type(type)
  end

  def symbolize_keys(hash)
    hash.inject({}) do |_, (k, v)|
      _.merge k.to_sym => v
    end
  end


  attr_reader :type, :raw_attributes, :raw_metadata, :other_resources
end