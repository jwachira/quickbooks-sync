module QuickBooksSync::ActsAsQuickBooksResource

  class Customer < ActiveRecord::Base

    extend ActiveRecordMethods

    acts_as_quick_books_resource do |config|
      config.attribute :name,       :full_name
      config.attribute :first_name
      config.attribute :last_name
      config.attribute :phone
    end

    validates_uniqueness_of :full_name

    named_scope :active, :conditions => { :deleted_at => nil }

    has_many :invoices, :class_name => "QuickBooksSync::ActsAsQuickBooksResource::Invoice"

    def deactivate!
      update_attribute(:deleted_at, Time.now)
    end

    def before_validation
      self.full_name = "#{first_name} #{last_name}" if self.full_name.blank?
    end

  end

end
