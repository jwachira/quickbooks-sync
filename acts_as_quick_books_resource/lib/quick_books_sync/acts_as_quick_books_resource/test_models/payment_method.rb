module QuickBooksSync::ActsAsQuickBooksResource

  class PaymentMethod < ActiveRecord::Base
    extend ActiveRecordMethods

    acts_as_quick_books_resource do |c|
      c.attribute :name
    end
  end

end
