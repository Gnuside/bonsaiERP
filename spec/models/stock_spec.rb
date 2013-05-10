require 'spec_helper'

describe Stock do
  it { should belong_to(:store) }
  it { should belong_to(:item) }
  it { should belong_to(:user) }

  it { should validate_numericality_of(:minimum) }
  it { should validate_presence_of(:store) }
  it { should validate_presence_of(:store_id) }
  it { should validate_presence_of(:item) }
  it { should validate_presence_of(:item_id) }

  subject { Stock.new }
  it { subject.quantity.should == 0 }
  it { should be_active }

  it "#save_minimum" do
    stock = Stock.new(quantity: 2, item_id: 1, store_id: 2, minimum: 0)
    stock.stub(item: true, store: true)
    stock.save.should be_true
    
    UserSession.user = build(:user, id: 25)
    stock.save_minimum(10).should be_true

    stock.user_id.should eq(25)

    stock.save_minimum(-1).should be_false
    stock.errors[:minimum].should eq([I18n.t("errors.messages.greater_than", count: 0)])

    stock.errors.clear
    stock.save_minimum('-0.2').should be_false
    stock.errors[:minimum].should eq([I18n.t("errors.messages.greater_than", count: 0)])

    stock.save_minimum(nil).should be_true
    stock.minimum.should == 0
  end
end
