require 'zlib'

module QuickBooksSync

  class ResourceSet
    extend QuickBooksSync::Memoizable
    include ResourceSet::BusinessLogic

    def initialize(seed)
      @by_id = if seed.respond_to?(:values)
        seed
      else
        ResourceSet.from_enumerator(seed).by_id
      end
    end

    attr_reader :by_id

    delegate :each, :to => :"by_id.values"

    class << self
      def from_enumerator(enum)
        by_id = {}

        enum.reject {|e| e.nil? }.each do |original_resource|
          resource = original_resource.with_other_resources(by_id)

          by_id[resource.id] = resource
        end

        ResourceSet.new(by_id)
      end

      def from_json(json)
        from_enumerator(if json.empty?
          []
        else
          JSON.parse(json)
        end.map do |type, attributes, metadata|
          (type && attributes && metadata) ?
            Resource.from_json(type, attributes, metadata) :
            nil
        end.compact)
      end

      alias :from_resources :from_enumerator
    end

    include Enumerable

    def sorted_by_type
      to_a.sort_by {|r| r.type.to_s }
    end

    delegate :to_json, :to => :sorted_by_type
    delegate :length, :size, :to => :by_id
    delegate :empty?, :to => :by_id


    def inspect
      "#<ResourceSet: #{to_a.inspect}>"
    end

    def reject
      ResourceSet.new(by_id.reject {|k, v| yield(v) })
    end

    def select
      reject {|v| !yield(v)}
    end

    def +(other)
      if other.respond_to? :by_id
        ResourceSet.new(by_id.merge(other.by_id))
      else
        self + ResourceSet.from_enumerator(other)
      end
    end

    def ==(other)
      by_id.keys.to_set == other.by_id.keys.to_set and by_id.all? {|k, v| v == other.by_id[k] }
    end

    def to_packaged
      string_io = StringIO.new
      io = Zlib::GzipWriter.new(string_io)

      each do |resource|
        json = resource.to_json
        io.puts json
      end

      io.print " "
      io.flush
      io.close

      string_io.string
    end

    SLICE_SIZE = 1000

    class PackageReader
      def initialize(io)
        @io = io
      end
      attr_reader :io

      def each
        io.each_line do |line|
          next if line.strip.empty?
          type, attributes, metadata = JSON.parse(line)
          yield Resource.from_json(type, attributes, metadata)
        end
      end

    end

    def self.from_packaged_io(io)
      from_io(Zlib::GzipReader.new(io))
    end

    def self.from_packaged_string(string)
      from_packaged_io(StringIO.new(string))
    end

    def self.from_io(io)
      from_enumerator(PackageReader.new(io).enum_for(:each))
    end

  end



end
