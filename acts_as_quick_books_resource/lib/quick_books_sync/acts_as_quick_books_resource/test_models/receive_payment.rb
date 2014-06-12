module QuickBooksSync::ActsAsQuickBooksResource

  class ReceivePayment < ActiveRecord::Base
    extend ActiveRecordMethods
    belongs_to :customer, :class_name => "QuickBooksSync::ActsAsQuickBooksResource::Customer"
    belongs_to :payment_method, :class_name => "QuickBooksSync::ActsAsQuickBooksResource::PaymentMethod"
    has_many   :applied_to_txns, :class_name => "QuickBooksSync::ActsAsQuickBooksResource::AppliedToTxn"

    acts_as_quick_books_resource do |c|
      c.attribute :customer
      c.attribute :payment_method
      c.attribute :applied_to_txns
      c.include_on_find :customer, :payment_method, :applied_to_txns
    end

  end

end