module QuickBooksSync::ActsAsQuickBooksResource

  class Configuration
    def initialize
      @attributes = {}
    end

    def id(local)
      @id_method = local
    end

    def attribute(quick_books, local=nil)
      quick_books = quick_books.to_sym
      @attributes[quick_books] = local ? local.to_sym : quick_books
    end

    def include_on_find(*assocs)
      @associations_to_include_on_find = assocs
    end

    def name(qb_name)
      @qb_name = qb_name
    end

    def update_only(*fields)
      @update_only_fields = fields.to_set
    end

    attr_reader :associations_to_include_on_find, :id_method, :metadata_method, :attributes, :qb_name, :update_only_fields
  end

end
