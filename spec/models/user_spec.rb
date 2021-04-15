require "spec_helper"

describe User do
  describe "self.current" do
    let(:user){ FactoryBot.create(:user) }
    before { User.current = user }
    it{ expect(User.current.id).to eq user.id }
  end

  describe "box_global_id" do
    let(:user){ FactoryBot.create(:user) }
    let(:box){ FactoryBot.create(:box)}
    context "with box" do
      before { 
        user.box = box
        user.save
      }
      it { expect(user.box_global_id).to eq(box.global_id)}
    end
    context "without box" do
      it { expect(user.box_global_id).to be_nil}
    end

  end

  describe "as_json" do
    let(:user){ FactoryBot.create(:user) }
    let(:box){ FactoryBot.create(:box)}
    before { 
      user.box = box
      user.save
    }
    it { expect(user.as_json).to include("box_id" => box.id)}
    it { expect(user.as_json).to include("box_global_id" => box.global_id)}
  end

  describe "create_search_columns" do
    let!(:column1) { FactoryBot.create(:search_column, user_id: 0, name: "name1", display_name: "display_name1", datum_type: "Specimen", display_order: 1, display_type: 0) }
    let!(:column2) { FactoryBot.create(:search_column, user_id: 0, name: "name2", display_name: "display_name2", datum_type: "Specimen", display_order: 2, display_type: 1) }
    let!(:column3) { FactoryBot.create(:search_column, user_id: 0, name: "name3", display_name: "display_name3", datum_type: "Specimen", display_order: 3, display_type: 2) }
    let(:user) { FactoryBot.build(:user_foo) }
    before { user.save! }
    describe "column1" do
      subject { SearchColumn.user_is(user).where(name: "name1") }
      it { expect(subject.count).to eq 1 }
      it { expect(subject.first.display_name).to eq "display_name1" }
      it { expect(subject.first.datum_type).to eq "Specimen" }
      it { expect(subject.first.display_order).to eq 1 }
      it { expect(subject.first.display_type).to eq 0 }
    end
    describe "column2" do
      subject { SearchColumn.user_is(user).where(name: "name2") }
      it { expect(subject.count).to eq 1 }
      it { expect(subject.first.display_name).to eq "display_name2" }
      it { expect(subject.first.datum_type).to eq "Specimen" }
      it { expect(subject.first.display_order).to eq 2 }
      it { expect(subject.first.display_type).to eq 1 }
    end
    describe "column3" do
      subject { SearchColumn.user_is(user).where(name: "name3") }
      it { expect(subject.count).to eq 1 }
      it { expect(subject.first.display_name).to eq "display_name3" }
      it { expect(subject.first.datum_type).to eq "Specimen" }
      it { expect(subject.first.display_order).to eq 3 }
      it { expect(subject.first.display_type).to eq 2 }
    end
  end

  describe "validates" do
    describe "api_key", :current => true do
      let(:obj) { FactoryBot.build(:user, api_key: api_key,email: "test1@test.co.jp") }
      context "is presence" do
        let(:api_key) { "111111" }
        it { expect(obj).to be_valid }
      end
      context "is blank" do
        let(:api_key) { "" }
        it { expect(obj).to be_valid }
      end
      context "is duplicate" do
        let(:user){ FactoryBot.create(:user) }
        let(:api_key) { user.api_key }
        it { expect(obj).not_to be_valid }
      end
      context "is duplicate empty" do
        let(:user){ FactoryBot.create(:user, username: 'deleteme-1', api_key: "") }
        let(:api_key) { user.api_key }
        it { expect(obj).to be_valid }
        it { expect(obj.save).to be_truthy }
      end
    end
    describe "name" do
      let(:obj) { FactoryBot.build(:user, username: username,email: "test1@test.co.jp") }
      context "is presence" do
        let(:username) { "sample_user" }
        it { expect(obj).to be_valid }
      end
      context "is blank" do
        let(:username) { "" }
        it { expect(obj).not_to be_valid }
      end
      context "is 255 characters" do
        let(:username) { "a" * 255 }
        it { expect(obj).to be_valid }
      end
      context "is 256 characters" do
        let(:username) { "a" * 256 }
        it { expect(obj).not_to be_valid }
      end
      context "is duplicate" do
        let(:user){ FactoryBot.create(:user) }
        let(:username) { user.username }
        it { expect(obj).not_to be_valid }
      end
    end
  end

end
