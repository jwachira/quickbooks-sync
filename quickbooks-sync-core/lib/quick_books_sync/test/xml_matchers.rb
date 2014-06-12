module XmlMatchers

  def be_xml(expected)
    XmlMatcher.new expected
  end

  class XmlMatcher
    include QuickBooksSync

    attr_reader :expected, :given, :failure_message, :negative_failure_message
    def initialize(expected)
      @expected = expected
    end

    def matches?(given)
      @given = given

      expected_node, given_node = [expected, given].
        map {|xml| Nokogiri.XML(xml).root }

      begin
        node_matches expected_node, given_node
        self.negative_failure_message = "expected xml to differ"
        true
      rescue XmlDoesNotMatch => e
        expected, actual, type = e.message
        self.failure_message = "expected #{type} #{actual.inspect} to == #{expected.inspect}; given xml = #{pretty_xml(given_node)}"
        false
      end
    end

    private
    attr_writer :failure_message, :negative_failure_message

    def node_matches(a, b)
      if [a,b].any?(&:nil?)
        assert_equal(a, b, "emptiness")
      elsif [a,b].all?(&:nil?)
        true
      elsif a.text? and b.text?
        assert_equal a.text, b.text, "node text"
      else
        element_matches(a, b)
        children_a, children_b = [a,b].map {|e| e.children.reject {|e| e.text? and e.text.strip.empty? }}

        assert_equal children_a.length, children_b.length, "number of children for #{a.name}"
        children_a.zip(children_b).each do |na, nb|
          node_matches(na, nb)
        end
      end
    end

    def element_matches(a,b)
      assert_equal a.name, b.name, "element name"
      attributes_match(a, b)
    end

    class XmlDoesNotMatch < Exception; end

    def assert_equal(a, b, type)
      raise XmlDoesNotMatch.new([a,b, type]) if a != b
    end

    def attributes_match(a,b)
      a, b = [a,b].map {|e| normalize_attributes(e) }
      assert_equal a,b, "attributes"
    end

    def normalize_attributes(element)
      element.attributes.map {|name, attribute| [name, attribute.value]}.
        inject({}) {|_, (k, v)| _.merge k => v}
    end


  end


end
