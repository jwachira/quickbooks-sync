module QuickBooksSync::ActsAsQuickBooksResource

  class Item < ActiveRecord::Base

    before_save do |model|
      raise "Item is abstract" if model.class == Item
    end

    extend ActiveRecordMethods

    acts_as_quick_books_resource do |c|
      c.attribute :name
    end
  end

  QuickBooksSync::Resource::TYPES.keys.select {|k| k =~ /^Item.+/}.each do |type|
    const_set type, Class.new(Item)
  end
end
