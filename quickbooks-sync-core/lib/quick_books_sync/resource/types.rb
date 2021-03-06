module QuickBooksSync

  class Resource
    # define all the autogenerated classes
    ClassGenerator = QuickBooksSync::ClassGenerator
    ClassGenerator.generate(self)

    # reopen them and fix the stuff we don't like.
    BALANCE_REMAINING = ClassGenerator.field_from_metadata({
      :name => "balance_remaining",
      :element_name => "BalanceRemaining",
      :type => :amount,
      :unchangeable_on_quickbooks => true
    })


    class Invoice
      def self.field_names
        [:customer, :invoice_lines, :balance_remaining]
      end

      extra_fields :balance_remaining => BALANCE_REMAINING

      def self.modable_on_quickbooks?
        false
      end
    end

    class Customer
      def self.field_names
        [:name, :company_name, :is_active, :job_status, :first_name, :last_name, :suffix, :phone, :email]
      end
    end

    class InvoiceLine
      def self.field_names
        [:item, :quantity, :rate]
      end
    end

    class Item
      def self.modable_on_quickbooks?
        false
      end
    end

    Item.subclasses.each do |subclass|
      subclass.instance_eval do
        def self.modable_on_quickbooks?
          false
        end

        def self.field_names
          [:name]
        end
      end
    end

    class PaymentMethod
      def self.field_names
        [:name]
      end

      def self.iterator?
        false
      end
    end

    class ReceivePayment
      class << self

        def addable_to_remote?
          false
        end

        def queryable_from_quickbooks?
          false
        end

        def field_names
          [:customer, :total_amount, :payment_method, :applied_to_txns]
        end

        def modable?
          false
        end
      end

      APPLIED_TO_TXN = ClassGenerator.field_from_metadata(
        :type=>:nested,
        :element_name=>"AppliedToTxnRet",
        :target=>"AppliedToTxn",
        :name=>"applied_to_txns")

       TOTAL_AMOUNT = ClassGenerator.field_from_metadata(
         :type => :sum,
         :name => "total_amount"
       )


      extra_fields(
        :applied_to_txns => APPLIED_TO_TXN,
        :total_amount => TOTAL_AMOUNT)
    end

    class AppliedToTxn

      class << self
        def field_names
          [ :invoice, :payment_amount ]
        end
      end

      INVOICE = ClassGenerator.field_from_metadata(
        :type => :unwrapped_ref,
        :target => "Invoice",
        :name => "invoice",
        :element_name => "TxnID"
      )

      extra_fields :invoice => INVOICE
    end

    class CreditMemo
      def self.field_names
        [:customer, :credit_memo_lines, :balance_remaining]
      end

      def self.modable_on_quickbooks?
        false
      end

      def self.addable_to_remote?
        false
      end

      def self.modable_on_remote?
        false
      end

      extra_fields :balance_remaining => BALANCE_REMAINING

    end

    class CreditMemoLine
      def self.field_names
        [:item, :quantity, :rate]
      end
    end


  end

end

