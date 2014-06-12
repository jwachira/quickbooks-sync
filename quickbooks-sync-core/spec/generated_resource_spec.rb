require File.dirname(__FILE__) + '/spec_helper'

context "generated resource classes" do

  T = QuickBooksSync::Resource

  def self.classes_by_key
    T.subclasses.inject({}) do |_, klass|
      _.merge klass.type.to_sym => klass
    end
  end
  delegate :classes_by_key, :to => :"self.class"

  def class_names
    classes_by_key.keys
  end

  it "should define the correct classes" do
    class_names.to_set.should == Set[
      :Invoice,
      :ItemDiscount,
      :ItemSubtotal,
      :ItemFixedAsset,
      :ItemNonInventory,
      :Customer,
      :ItemGroup,
      :ItemOtherCharge,
      :InvoiceLine,
      :Item,
      :ItemService,
      :ItemInventoryAssembly,
      :ItemInventory,
      :ItemSalesTaxGroup,
      :ItemPayment,
      :ItemSalesTax,
      :PaymentMethod,
      :ReceivePayment,
      :AppliedToTxn,
      :CreditMemo,
      :CreditMemoLine
      ]
  end

  def should_be_subclass_of(superclass)

    simple_matcher("should be a subclass of #{superclass}") do |actual|
      actual.is_a?(Class) and superclass.is_a?(Class) and actual < superclass
    end
  end

  classes_by_key.each do |name, klass|
    describe name do
      it "should be a Resource" do
        klass.should should_be_subclass_of(QuickBooksSync::Resource)
      end
    end
  end

  [:ItemDiscount, :ItemSubtotal, :ItemFixedAsset, :ItemNonInventory, :ItemOtherCharge, :ItemService, :ItemInventoryAssembly, :ItemInventory, :ItemSalesTaxGroup, :ItemPayment, :ItemSalesTax].each do |item_subclass|
    describe item_subclass do
      subject { classes_by_key[item_subclass] }

      it "should be a subclass of Item" do
        subject.superclass.should == T::Item
      end

      it "should have only 'name' as a field" do
        subject.field_names.should == [:name]
      end

      it { should_not be_abstract }
      it { should_not be_top_level }
      it { should_not be_modable_on_quickbooks }
      specify { subject.concrete_superclass.should == T::Item }
    end
  end

  describe T::PaymentMethod do
    subject { T::PaymentMethod }

    it "should have only field and is_active as fields" do
      subject.field_names.should == [:name]
    end

    it "should have list_id as key name" do
      subject.key_name.should == "ListID"
    end

    it { should_not be_modable_on_quickbooks }
  end

  describe T::Item do
    subject { T::Item }

    it { should be_abstract }
    it { should be_top_level }
    it { should_not be_nested }
    it { should_not be_modable_on_quickbooks }
    it { should be_addable_to_remote }
    specify { subject.concrete_superclass.should == subject }
  end

  describe T::Invoice do
    subject { T::Invoice }
    it { should_not be_abstract }
    it { should_not be_nested }
    it { should_not be_modable_on_quickbooks }
    specify { subject.concrete_superclass.should == subject }
    it { should be_addable_to_remote }
  end

  describe T::Customer do
    subject { T::Customer }
    it { should_not be_abstract }
    it { should_not be_nested}
    it { should be_modable_on_quickbooks }
    specify { subject.concrete_superclass.should == subject }
    it { should be_addable_to_remote }
  end

  describe T::InvoiceLine do
    subject { T::InvoiceLine }
    it { should_not be_abstract }
    it { should_not be_top_level }
    it { should be_nested }
    it { should be_modable_on_quickbooks }
    it { should be_addable_to_remote }
  end

  describe T::ReceivePayment do
    subject { T::ReceivePayment }
    it { should_not be_addable_to_remote }
    it { should_not be_queryable_from_quickbooks }
  end

  describe T::CreditMemo do
    subject { T::CreditMemo }
    it { should_not be_abstract }
    it { should_not be_nested }
    it { should_not be_modable_on_quickbooks }
    specify { subject.concrete_superclass.should == subject }
    it { should_not be_addable_to_remote }
  end

  describe T::CreditMemoLine do
    subject { T::CreditMemoLine }
    it { should_not be_abstract }
    it { should_not be_top_level }
    it { should be_nested }
    it { should be_modable_on_quickbooks }
    it { should be_addable_to_remote }
  end

end
