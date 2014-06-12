class QuickBooksSync::Field
  include QuickBooksSync::XmlBuilder

  def initialize(resource)
    @resource = resource
  end
  attr_reader :resource

  delegate :raw_attributes, :other_resources, :to => :resource

  delegate :name,
           :nested?,
           :reference?,
           :unwrapped_reference?,
           :sum?,
           :enum?,
           :element_name,
           :target_type,
           :max_length,
           :choices,
           :unchangeable_on_quickbooks?,
           :to => :"self.class"

  def value
    if reference? or unwrapped_reference?
      raw.resolve(other_resources) if raw
    else
      raw
    end
  end

  def serialized_value
    if reference? or unwrapped_reference?
      raw.target_id if raw
    else
      raw
    end
  end

  def reference_id(other_metadata)
    id = [target_type, raw.target_id]

    if updated = other_metadata[id]
      updated.metadata[:quick_books_id]
    else
      raw.target_id
    end
  end

  def raw
    raw_attributes[name]
  end

  def defined?
    sum? or raw_attributes.has_key?(name)
  end


  def to_xml(operation, other_metadata)
    if unwrapped_reference?
      element_tag {|x| x.text!(reference_id(other_metadata)) }
    elsif reference?
      element_tag {|x| x.ListID { x.text!(reference_id(other_metadata)) } }
    elsif nested?
      raw.map {|resource| resource.to_xml(operation, other_metadata) }.join
    elsif sum?
      payment_sum_hack
    elsif value = serialized_value
      element_tag {|x| x.text!(value.to_s) }
    else
      ""
    end
  end

  # This is a totally nasty one-off for QuickBooks' requirement that a ReceivePayment
  # have a denormalized sum of all transaction payment amounts.
  # we may want to get field classes per field type to make this is much easier;
  # currently we have field classes per backing type (XML, JSON, concrete, activerecord);
  # having mixins for that might be better

  def payment_sum_hack
    total = resource["applied_to_txns"].inject(0) do |_, txn|
      _ + QuickBooksSync::PennyConverter.to_pennies(txn['payment_amount'])
    end

    string = QuickBooksSync::PennyConverter.from_pennies(total)

    "<TotalAmount>#{string}</TotalAmount>"
  end

  def element_tag
    builder {|x| x.tag!(element_name) { yield x }}
  end

  def error
    return unless serialized_value
    if max_length and value.length > max_length
       "Input too long: #{value.length} > #{max_length}"
    elsif enum? and !choices.include?(value)
      "\"#{value}\" not a valid choice"
    end
  end


end
