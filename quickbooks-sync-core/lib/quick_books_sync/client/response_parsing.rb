class QuickBooksSync::Client
  module ResponseParsing

    class ResponseFragment
      def initialize(response_element)
        @response_element = response_element
      end

      attr_reader :response_element

      def request_id
        response_element["requestID"].to_i
      end

      def resource_elements
        response_element.children.reject(&:text?)
      end

      def remaining
        response_element["iteratorRemainingCount"].to_i
      end

      def iterator_id
        response_element["iteratorID"]
      end

      def severity
        response_element["statusSeverity"]
      end

      def message
        response_element["statusMessage"]
      end

      def error?
        severity.downcase == 'error'
      end

      def raise_if_error!
        raise QuickBooksSync::QuickBooksException.new(message) if error?
      end

    end

    def parse_responses(response)
      response.css("[requestID]").to_a.
        map {|response_element| ResponseFragment.new(response_element) }
    end

  end
end
