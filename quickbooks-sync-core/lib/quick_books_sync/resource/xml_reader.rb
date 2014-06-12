require 'quick_books_sync/util'

class QuickBooksSync::Resource::XmlReader
  include QuickBooksSync
  extend QuickBooksSync::Memoizable

  def initialize(xml, connection, provided_type=nil)
    @xml, @connection, @provided_type = xml, connection, provided_type
  end
  attr_reader :xml, :connection, :provided_type

  def to_resource
    data = fields.to_hash_keyed_by_with_values do |field|
      [field.name, get_from_field(field)]
    end.reject {|k, v| v.nil? }

    metadata = Resource.metadata_from_object(self)

    type_class.new data, metadata, {}
  end

  def type
    provided_type || xml.name.match(/(.*)Ret$/)[1]
  end

  def get_from_field(field)
    if field.reference?
      type = field.target_type
      node = node(field.element_name)
      if node
        id = node.css("ListID").inner_text
        Resource::Reference.new(type, id)
      end
    elsif field.nested?
      css(field.element_name).map do |element|
        self.class.new(element, connection, field.target_type).to_resource
      end
    else
      content(field.element_name)
    end
  end

  def type_class
    Resource.of_type(type)
  end

  delegate :fields, :field, :key_name, :to => :type_class


  def [](key)
    field(key).get
  end

  def updated_at
    time_or_nil "TimeModified"
  end

  def created_at
    time_or_nil "TimeCreated"
  end

  def quick_books_id
    content(key_name)
  end

  def vector_clock
    content("EditSequence")
  end

  def content(name)
    node = node(name)
    node and node.inner_text
  end

  def node(name)
    xml.css(name).first
  end

  delegate :children, :css, :to => :xml

  private

  def time_or_nil(name)
    if raw = content(name)
      correct_for_dst_fuckup(Time.parse(raw))
    end
  end

  def correct_for_dst_fuckup(time)
    if connection.correct_for_daylight_savings_time?
      Time.at(time.to_i - 3600)
    else
      time
    end
  end

end