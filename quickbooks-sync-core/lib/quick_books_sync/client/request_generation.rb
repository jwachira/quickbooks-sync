class QuickBooksSync::Client
  include QuickBooksSync::XmlBuilder

  module RequestGeneration
    class RequestBatch
      include QuickBooksSync::XmlBuilder
      def initialize(requests = [])
        @requests = requests
        yield self if block_given?
      end

      def append_request(name, xml = nil, options={}, &callback)
        requests << OpenStruct.new({:name => name, :xml => xml,  :callback => callback}.merge(options))
      end

      def add(name, xml, &callback)
        append_request("#{name}AddRq", xml, &callback)
      end

      def query(name, xml=nil, options={}, &callback)
        append_request "#{name}QueryRq", xml, options, &callback
      end

      def modify(resource, &callback)
        append_request("#{resource.type}ModRq", resource.to_xml(:mod), &callback)
      end

      def delete(id)
        type, id = id
        xml = builder do |x|
          x.ListDelType(type)
          x.ListID(id)
        end

        append_request "ListDelRq", xml
      end

      attr_reader :requests
    end


    def qbxml
      builder do |x|
        x.instruct!
        x.instruct! :qbxml, :version => '6.0'
        x.QBXML { yield x }
      end
    end

    def generate_request_xml(indexed_requests, options={})
      on_error = options[:on_error] || :stop

      xml = qbxml do |x|
        x.QBXMLMsgsRq(:onError => "#{on_error.to_s}OnError") do |x|
          indexed_requests.sort_by {|i, request| i }.each do |i, request|
            xml_block = if request.xml
              lambda {|b| b << request.xml}
            end

            options = {
              :requestID => i,
              :iterator => request.iterator,
              :iteratorID => request.iterator_id}.
            reject {|k, v| v.nil? }

            x.tag!(request.name, options, &xml_block)

          end
        end
      end

    end






  end

end
