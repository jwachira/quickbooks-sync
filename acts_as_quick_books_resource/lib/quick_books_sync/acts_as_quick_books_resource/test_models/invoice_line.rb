module QuickBooksSync::ActsAsQuickBooksResource

  class InvoiceLine < ActiveRecord::Base
    extend ActiveRecordMethods

    acts_as_quick_books_resource do |config|
      config.attribute :quantity
      config.attribute :item
      config.attribute :rate
    end

    belongs_to :invoice, :class_name => "QuickBooksSync::ActsAsQuickBooksResource::Invoice"
    belongs_to :item, :class_name => "QuickBooksSync::ActsAsQuickBooksResource::Item"

    acts_as_pennies :rate


  end

end
