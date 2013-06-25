# encoding: utf-8
require 'spec_helper'

describe Expenses::InventoryOut do
  let(:store) { build :store, id: 1 }

  before(:each) do
    ExpenseDetail.any_instance.stub(item: true)
    Expense.any_instance.stub(contact: true, set_supplier_and_expenses_status: true)
  end

  let(:contact) {
    cont = build :contact
    cont.stub(save: true)
    cont
  }

  let(:expense) {
    exp = Expense.new_expense(
      attributes_for(:expense_approved).merge(
        contact_id: 3, balance_inventory: 0,
        expense_details_attributes: [
          {item_id: 1, quantity: 5, price: 10, balance: 0},
          {item_id: 2, quantity: 5, price: 10, balance: 0}
        ]
      )
    )
    exp.save
    exp
  }

  let(:valid_attributes) {
    {store_id: 1, date: Date.today, description: 'Test inventory out', 
     expense_id: expense.id,
     inventory_details_attributes: [
       {item_id: 1, quantity: 2},
       {item_id: 2, quantity: 2}
    ]
    }
  }
  let(:item) { build :item }
  let(:store) { build :store }
  let(:user) { build :user, id: 10 }

  context 'create' do
    before(:each) do
      UserSession.user = user
      Income.any_instance.stub(contact: contact)
      Store.stub_chain(:active, where: [store])
      InventoryDetail.any_instance.stub(item: item)
    end

    def create_inventory_in
      inv = Inventories::In.new(valid_attributes.merge({
        inventory_details_attributes: [
          {item_id: 1, quantity: 4},
          {item_id: 2, quantity: 5}
        ]
      }))
      inv.create
    end

    it "#delivers" do
      Inventory.any_instance.stub(store: store)
      Stock.any_instance.stub(item: item, store: store)

      # Create with the function
      create_inventory_in.should be_true

      # Create
      invout = Expenses::InventoryOut.new(valid_attributes)
      invout.create.should be_true

      inv = Inventory.find(invout.inventory.id)
      inv.should be_is_a(Inventory)
      inv.should be_is_exp_out
      inv.creator_id.should eq(user.id)
      inv.ref_number.should =~ /\AS-\d{2}-\d{4}\z/
      expect(inv.account_id).to eq(expense.id)

      exp = Expense.find(inv.account_id)
      exp.balance_inventory.should == 40
      exp.details[0].balance.should == 2
      exp.details[1].balance.should == 2

      inv.details.should have(2).items
      inv.details.map(&:quantity).should eq([2, 2])
      inv.details.map(&:item_id).should eq([1, 2])

      stocks = Stock.active.where(store_id: inv.store_id)
      stocks.should have(2).items
      stocks.map(&:item_id).sort.should eq([1, 2])
      stocks.map(&:quantity).should eq([2, 3])

      # More items
      attrs = valid_attributes
      attrs[:inventory_details_attributes][0][:quantity] = 3
      attrs[:inventory_details_attributes][1][:quantity] = 3

      invout = Expenses::InventoryOut.new(attrs)
      invout.create.should be_true

      exp = Expense.find(expense.id)
      exp.balance_inventory.should == 100
      exp.details[0].balance.should == 5
      exp.details[1].balance.should == 5

      io = Inventory.find(invout.inventory.id)
      io.should be_has_error
      io.error_messages["quantity"].should eq(['inventory.negative_stock'])
      io.error_messages["item_ids"].should eq([1])

      io.inventory_details.should have(2).items
      io.inventory_details.map(&:quantity).should eq([3, 3])
      io.inventory_details.map(&:item_id).should eq([1, 2])

      stocks = Stock.active.where(store_id: io.store_id)
      stocks.should have(2).items
      stocks.map(&:item_id).sort.should eq([1, 2])
      stocks.map(&:quantity).should eq([-1, 0])

      # Error
      invout = Expenses::InventoryOut.new(valid_attributes)
      invout.create.should be_false
      invout.details[0].errors[:quantity].should eq([I18n.t('errors.messages.inventory.movement_quantity')])
      invout.details[1].errors[:quantity].should_not be_blank

      # Error
      invout = Expenses::InventoryOut.new(valid_attributes.merge(
        inventory_details: [{item_id: 100, quantity: 1}]
      ))

      invout.create.should be_false
      invout.errors[:base].should_not be_blank
    end
  end
end