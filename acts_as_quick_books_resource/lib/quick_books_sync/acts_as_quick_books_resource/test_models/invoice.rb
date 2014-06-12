module QuickBooksSync::ActsAsQuickBooksResource

  class Invoice < ActiveRecord::Base
    extend ActiveRecordMethods

    acts_as_quick_books_resource do |config|
      config.attribute :invoice_lines, :lines
      config.attribute :customer
      config.include_on_find({:lines => [:item]}, :customer)
    end

    belongs_to :customer, :class_name => "QuickBooksSync::ActsAsQuickBooksResource::Customer"
    has_many :lines, :class_name => 'QuickBooksSync::ActsAsQuickBooksResource::InvoiceLine'
  end

end