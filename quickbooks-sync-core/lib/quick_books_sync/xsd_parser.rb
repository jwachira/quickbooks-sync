require 'rubygems'
require 'nokogiri'

module QuickBooksSync
  class XsdParser

    def self.generate(file)
      new(file).attributes_by_type
    end

    # protected

    def initialize(filename)
      @filename = filename
      @document = doc(filename)

      css('xsd|include').each do |node|
        substitution = doc(node['schemaLocation'])
        substitution.children.each do |child|
          node.add_previous_sibling child
        end
        node.unlink
      end
    end

    def attributes_by_type
      type_names.inject({}) do |_, type|
        _.merge type => Type.new(self, type).generate
      end
    end


    private

    class Type
      extend QuickBooksSync::Memoizable

      def initialize(parser, type)
        @parser, @type = parser, type
      end

      def generate
        if abstract?
          abstract
        else
          concrete
        end
      end

      private

      def concrete

        attributes = all_attributes.reject do |attribute|
          (FIELDS_TO_IGNORE + (FIELDS_TO_IGNORE_PER_TYPE[type] || [])).include? attribute[:name]
        end.to_a

        {
          :include_line_items => include_line_items?,
          :fields => attributes,
          :deletable => deletable?,
          :modable => modable_on_quickbooks?,
          :key_name => key_name,
          :top_level => top_level?,
          :abstract => false
        }
      end

      def all_attributes
        fields.map(&:flatten).flatten.compact.map(&:serialize)
      end

      memoize :all_attributes


      def include_line_items?
        css("xsd|group[name=#{type}Query] xsd|element[ref=IncludeLineItems]").any?
      end

      def deletable?
        css("xsd|element[name=ListDelType] xsd|enumeration").map {|e| e[:value]}.include?(type)
      end

      def modable_on_quickbooks?
        !!mod_element
      end

      def key_name
        mapping = if mod_element
          {"ListCoreMod" => "ListID", "TxnCoreMod" => "TxnID"}
        elsif add_element
          {"ListCore" => "ListID", "TxnCore" => "TxnID"}
        end

        element = mod_element || ret_element

        key = mapping.keys.detect do |core|
          element.css("xsd|group[ref=#{core}]").any?
        end

        mapping[key]
      end

      def top_level?
        css("xsd|element[name=#{type}QueryRq]").any?
      end

      def abstract
        {:abstract => true,
         :concrete_subtypes => concrete_subclasses}
      end

      def concrete_subclasses
        css("xsd|complexType[name=#{type}QueryRsType] xsd|choice xsd|element").map do |element|
          element['ref'].gsub(/Ret$/, "")
        end
      end

      def abstract?
        !(mod_element or add_element)
      end

      def mod_element
        css("xsd|element[name=#{type}Mod]").first
      end

      def add_element
        css("xsd|element[name=#{type}Add]").first
      end

      def ret_element
        css("xsd|element[name=#{type}Ret]").first
      end

      def fields
        main_element.css("xsd|sequence").first.children.map {|element| Field.new(self, element) }
      end

      def main_element
        mod_element or add_element
      end

      memoize :mod_element, :add_element, :ret_element, :main_element, :concrete_subclasses
      private

      attr_reader :parser, :type
      delegate :document, :css, :to => :parser

    end

    class Field
      def initialize(resource_type, element, parent_element = nil)
        @resource_type, @element, @parent_element = resource_type, element, parent_element
      end

      def fields_to_serialize
        [:name, :type, :element_name, :required]
      end

      def serialize
        fields_to_serialize.inject({}) do |_, field|
          if respond_to?(field)
            _.merge field => send(field)
          else
            _
          end
        end
      end

      def required
        element["minOccurs"] != "0" and if parent_element
          parent_element["minOccurs"] != "0"
        else
          true
        end
      end

      def name
        if element_name
          element_name.snake_case
        else
          raise element.serialize
        end
      end

      def flatten
        if group?
          fields_from_group
        elsif qb_ref?
          QuickBooksReferenceField.new(resource_type, element, parent_element).flatten
        elsif ref?
          fields_from_reference
        elsif enum?
          EnumField.new(resource_type, element)
        elsif string?
          StringField.new(resource_type, element)
        elsif choice?
          fields_from_choice
        elsif !ignorable?
          [self]
        end
      end

      def group?
        element.name == "group"
      end

      def qb_ref?
        element_name and element_name =~ /(.*)Ref$/
      end

      def ref?
        element.name == "element" and element["ref"]
      end

      def enum?
        type == :enum
      end

      def string?
        type == :string
      end

      def choice?
        element.name == "choice"
      end


      def ignorable?
        element.text? or ["EditSequence", "ListID", "TxnID"].include? element_name
      end

      def fields_from_group
        css("xsd|group[name=#{ref_name}] xsd|element").map {|element| Field.new(resource_type, element).flatten }
      end

      def fields_from_reference
        Field.new(type, css("xsd|element[name=#{ref_name}]").first, element).flatten
      end

      def fields_from_choice
        element.css("xsd|element").map {|element| ChoiceField.new(resource_type, element) }
      end

      def ref_name
        element["ref"]
      end

      def element_name
        element["name"]
      end


      def extract_type
        if element["type"]
          element["type"]
        elsif (restrictions = element.children.css('xsd|restriction') and !restrictions.empty?)
          restrictions.first['base']
        end
      end

      def type
        {"STRTYPE" => :string,
         "DATETYPE" => :date,
         "IDTYPE" => :id,
         "BOOLTYPE" => :boolean,
         "ENUMTYPE" => :enum,
         "AMTTYPE" => :amount,
         "INTTYPE" => :integer,
         "QUANTYPE" => :quantity,
         "PRICETYPE" => :price,
         "PERCENTTYPE" => :percent,
         }[extract_type] || nil
      end


      private

      attr_reader :resource_type, :element, :parent_element

      delegate :css, :to => :resource_type
    end

    class StringField < Field
      def max_length
        if length_element = element.children.css('xsd|maxLength').first
          length_element['value'].to_i
        end
      end

      def fields_to_serialize
        super + [:max_length]
      end
    end

    class EnumField < Field

      def choices
        element.css("xsd|restriction[base=ENUMTYPE] xsd|enumeration").map {|v| v["value"] }
      end

      def fields_to_serialize
        super + [:choices]
      end
    end

    class SimpleField < Field
      def name
        element["name"].snake_case
      end
    end

    class QuickBooksReferenceField < Field
      def target
        element_name.gsub(/Ref$/, "")
      end

      def type
        :ref
      end

      def name
        target.snake_case
      end

      def element_name
        element["name"]
      end

      def flatten
        [self]
      end

      def fields_to_serialize
        super + [:target, :element_name]
      end
    end

    class ChoiceField < Field

      def type
        :nested
      end

      def name
        target.snake_case + "s"
      end

      def target
        element["ref"].gsub(/Mod$/, "")
      end

      def element_name
        target + "Ret"
      end

      def fields_to_serialize
        [:type, :name, :target, :element_name]
      end
    end

    attr_reader :document, :filename

    def type_names
      ["Customer",
      "Item",
      "Invoice",
      "InvoiceLine",
      "ItemInventory",
      "ItemPayment",
      "ItemDiscount",
      "ItemNonInventory",
      "ItemSalesTaxGroup",
      "ItemFixedAsset",
      "ItemService",
      "ItemGroup",
      "ItemInventoryAssembly",
      "ItemSalesTax",
      "ItemSubtotal",
      "ItemOtherCharge",
      "ReceivePayment",
      "PaymentMethod",
      "AppliedToTxn",
      "CreditMemo",
      "CreditMemoLine",
      ]
    end

    def doc(doc_filename)
      absolute = File.expand_path(doc_filename, File.dirname(filename))
      Nokogiri::XML(File.open(absolute)).root
    end

    FIELDS_TO_IGNORE = ["edit_sequence", "list_id", "txn_id"]
    FIELDS_TO_IGNORE_PER_TYPE = {
      "Customer" => ["is_statement_with_parent", "delivery_method"]
    }


    delegate :css, :to => :document
  end
end
