# require 'quick_books_sync/Interop.QBFC8' if IRONRUBY

require 'quick_books_sync/client/request_generation'
require 'quick_books_sync/client/response_parsing'

require 'builder'
require 'ostruct'

module QuickBooksSync

  class Client

    def initialize(connection)
      @connection = connection
    end

    extend Memoizable

    def request(options={}, &block)
      execute RequestBatch.new(&block), options
    end

    def execute(batch, options={})
      while !batch.requests.empty?
        batch = execute_page batch, options
      end
    end

    def execute_page(batch, options={})
      indexed_requests = index_requests(batch)
      return if indexed_requests.empty?
      xml = generate_request_xml indexed_requests, options

      response = QuickBooksSync::XML.XML connection.request(xml)

      all_responses = parse_responses(response)

      remaining_records = all_responses.select do |parsed|
        parsed.remaining > 0
      end

      all_responses.each do |parsed|
        request = indexed_requests[parsed.request_id]
        request.callback.call(parsed) if request.callback
      end

      next_page_requests = remaining_records.map do |parsed|
        request = indexed_requests[parsed.request_id]
        new_request = request.dup
        new_request.iterator = "Continue"
        new_request.iterator_id = parsed.iterator_id

        new_request
      end

      RequestBatch.new(next_page_requests)
    end

    def index_requests(batch)
      batch.requests.enum_for(:each_with_index).inject({}) do |_, (request, i)|
        _.merge i => request
      end
    end

    attr_reader :connection
    delegate :close, :correct_for_daylight_savings_time?, :to => :connection
    private



    include RequestGeneration
    include ResponseParsing

  end

end
