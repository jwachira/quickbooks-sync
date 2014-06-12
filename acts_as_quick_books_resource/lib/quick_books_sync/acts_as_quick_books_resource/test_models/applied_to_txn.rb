module QuickBooksSync::ActsAsQuickBooksResource

  class AppliedToTxn < ActiveRecord::Base
    extend ActiveRecordMethods
    belongs_to :invoice, :class_name => "QuickBooksSync::ActsAsQuickBooksResource::Invoice"

    acts_as_quick_books_resource do |c|
      c.attribute :payment_amount
      c.attribute :invoice
    end

    acts_as_pennies :payment_amount

  end

end