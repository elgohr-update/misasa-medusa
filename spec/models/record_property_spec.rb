require "spec_helper"

describe RecordProperty do
  shared_examples "checking user permission" do |method, owner_permission_attribute, group_permission_attribute, guest_permission_attribute|
    subject { record_property.send(method, user) }
    let(:record_property) { FactoryBot.build(:record_property, user_id: user_id, group_id: group_id, owner_permission_attribute => owner_permission, group_permission_attribute => group_permission, guest_permission_attribute => guest_permission) }
    let(:user) { FactoryBot.create(:user, administrator: admin) }
    let(:admin) { false }
    let(:group) { FactoryBot.create(:group) }
    before { GroupMember.create(user: user, group: group) }
    context "when user is owner." do
      let(:user_id) { user.id }
      let(:group_id) { nil }
      let(:group_permission) { false }
      let(:guest_permission) { false }
      context "when owner is permitted." do
        let(:owner_permission) { true }
        it { expect(subject).to be_truthy }
      end
      context "when owner is not permitted." do
        let(:owner_permission) { false }
        it { expect(subject).to be_falsey }
        context "when user is administrator." do
          let(:admin) { true }
          it { expect(subject).to be_truthy }
        end
      end
    end
    context "when user is not owner." do
      let(:user_id) { nil }
      let(:owner_permission) { true }
      context "when user belongs to group." do
        let(:group_id) { group.id }
        let(:guest_permission) { false }
        context "when group is permitted." do
          let(:group_permission) { true }
          it { expect(subject).to be_truthy }
        end
        context "when group is not permitted." do
          let(:group_permission) { false }
          it { expect(subject).to be_falsey }
          context "when user is administrator." do
            let(:admin) { true }
            it { expect(subject).to be_truthy }
          end
        end
      end
      context "when user does not belongs to group." do
        let(:group_id) { nil }
        let(:group_permission) { true }
        context "when guest is permitted." do
          let(:guest_permission) { true }
          it { expect(subject).to be_truthy }
        end
        context "when guest is not permitted." do
          let(:guest_permission) { false }
          it { expect(subject).to be_falsey }
          context "when user is administrator." do
            let(:admin) { true }
            it { expect(subject).to be_truthy }
          end
        end
      end
    end
  end

  describe ".datum_attributes" do
    subject { record_property.datum_attributes }
    let(:record_property) { FactoryBot.build(:record_property) }
    it { expect(subject).to include("global_id" => record_property.datum.global_id)}
  end

  describe ".writable?" do
    it_behaves_like "checking user permission", :writable?, :owner_writable?, :group_writable?, :guest_writable?
  end

  describe ".readable?" do
    it_behaves_like "checking user permission", :readable?, :owner_readable?, :group_readable?, :guest_readable?
  end

  describe ".owner?" do
    subject { record_property.owner?(user) }
    let(:record_property) { FactoryBot.build(:record_property, user_id: user_id) }
    let(:user) { FactoryBot.create(:user) }
    context "when match user_id" do
      let(:user_id) { user.id }
      it { expect(subject).to be_truthy }
    end
    context "when unmatch user_id" do
      let(:user_id) { nil }
      it { expect(subject).to be_falsey }
    end
  end

  describe ".group?" do
    subject { record_property.group?(user) }
    let(:record_property) { FactoryBot.build(:record_property, user: nil, group_id: group_id) }
    let(:user) { FactoryBot.create(:user) }
    let(:group) { FactoryBot.create(:group) }
    before { GroupMember.create(user: user, group: group) }
    context "when match group_id" do
      let(:group_id) { group.id }
      it { expect(subject).to be_truthy }
    end
    context "when unmatch group_id" do
      let(:group_id) { nil }
      it { expect(subject).to be_falsey }
    end
  end

  describe ".generate_global_id" do
    subject { obj.global_id }
    let(:obj){FactoryBot.build(:record_property,global_id: global_id)}
    before { obj.save }
    context "global_id is nil" do
      let(:global_id){nil}
      it{expect(subject).to be_present}
    end
    context "global_id is not nil" do
      let(:global_id){"aaa"}
      it{expect(subject).to eq global_id}
    end
  end

  describe ".dispose" do
    let(:obj){ FactoryBot.create(:record_property, disposed: false, disposed_at: nil) }
    before do
      obj.dispose
    end
    it { expect(obj.disposed).to eq true }
    it { expect(obj.disposed_at).to be_present }
  end

  describe ".restore" do
    let(:obj){ FactoryBot.create(:record_property, disposed: true, disposed_at: "2016-10-10 12:13:14") }
    before do
      obj.restore
    end
    it { expect(obj.disposed).to eq false }
    it { expect(obj.disposed_at).to be_nil }
  end

  describe ".adjust_pubulished_at" do
    subject { obj.published_at }
    let(:obj){FactoryBot.build(:record_property,published: published,published_at: published_at)}
    context "publishd true" do
      let(:published){true}
      before{obj.save}
      context "published_at is nil" do
        let(:published_at){nil}
        it{expect(subject).to be_present}
      end
      context "published_at is not nil" do
        let(:published_at){Time.now - 1}
        it{expect(subject).to eq published_at}
      end
    end
    context "publishd false" do
      let(:published){false}
      before{obj.save}
      context "published_at is nil" do
        let(:published_at){nil}
        it{expect(subject).to be_nil}
      end
      context "published_at is not nil" do
        let(:published_at){Time.now - 1}
        it{expect(subject).to be_nil}
      end
    end
  end

  describe ".adjust_disposed_at" do
    let(:obj){FactoryBot.build(:record_property, disposed: disposed, disposed_at: disposed_at)}
    before{ obj.save }
    subject { obj.disposed_at }
    context "disposed true" do
      let(:disposed){ true }
      context "disposed_at is nil" do
        let(:disposed_at){ nil }
        it{ expect(subject).to be_present }
      end
      context "disposed_at is not nil" do
        let(:disposed_at){ Time.now - 1.day }
        it{ expect(subject).to eq disposed_at }
      end
    end
    context "disposed false" do
      let(:disposed){ false }
      context "disposed_at is nil" do
        let(:disposed_at){ nil }
        it{ expect(subject).to be_nil }
      end
      context "disposed_at is not nil" do
        let(:disposed_at){ Time.now - 1.day }
        it{ expect(subject).to be_nil }
      end
    end
  end

  describe ".adjust_lost_at" do
    let(:obj){FactoryBot.build(:record_property, lost: lost, lost_at: lost_at)}
    before{ obj.save }
    subject { obj.lost_at }
    context "lost true" do
      let(:lost){ true }
      context "lost_at is nil" do
        let(:lost_at){ nil }
        it{ expect(subject).to be_present }
      end
      context "lost_at is not nil" do
        let(:lost_at){ Time.now - 1.day }
        it{ expect(subject).to eq lost_at }
      end
    end
    context "lost false" do
      let(:lost){ false }
      context "lost_at is nil" do
        let(:lost_at){ nil }
        it{ expect(subject).to be_nil }
      end
      context "lost_at is not nil" do
        let(:lost_at){ Time.now - 1.day }
        it{ expect(subject).to be_nil }
      end
    end
  end

  describe "callbacks" do
    describe "generate_global_id" do
      let(:user) { FactoryBot.create(:user) }
      context "global_id is nil" do
        let(:record_property){ FactoryBot.build(:record_property, user_id: user.id, global_id: nil) }
        before { record_property.save }
        it{ expect(record_property.global_id).to be_present }
      end
      context "global_id is not nil" do
        let(:record_property){ FactoryBot.build(:record_property, user_id: user.id, global_id: "xxx") }
        before { record_property.save }
        it{ expect(record_property.global_id).to eq "xxx" }
      end
    end
  end

  describe ".readables", :current => true do
    subject { RecordProperty.readables(user) }
    let(:record_property) { FactoryBot.create(:record_property, owner_readable: owner_readable, group_readable: group_readable, guest_readable: guest_readable, user_id: user_id, group_id: group_id, published: published) }
    let(:user) { FactoryBot.create(:user_foo, administrator: admin) }
    let(:admin) { false }
    let(:group) { FactoryBot.create(:group) }
    let(:another_user) { FactoryBot.create(:user_baa) }
    let(:another_group) { FactoryBot.create(:group) }
    let(:published){ false }
    before do
      GroupMember.create(user: user, group: group)
      record_property
    end
    context "when user is record owner." do
      let(:user_id) { user.id }
      let(:group_id) { another_group.id }
      let(:group_readable) { false }
      let(:guest_readable) { false }
      context "when owner is permitted to read." do
        let(:owner_readable) { true }
        it { expect(subject).to be_present }
      end
      context "when owner is not permitted to read." do
        let(:owner_readable) { false }
        it { expect(subject).to be_blank }
        context "when user is administrator." do
          let(:admin) { true }
          it { expect(subject).to be_present }
        end
        context "when record is published" do
          let(:published){ true }
          it { expect(subject).to be_present }
        end
      end
    end
    context "when user is not record owner." do
      let(:user_id) { another_user.id }
      let(:owner_readable) { true }
      context "when user belongs to record group." do
        let(:group_id) { group.id }
        let(:guest_readable) { false }
        context "when group member is permitted to read." do
          let(:group_readable) { true }
          it { expect(subject).to be_present }
        end
        context "when group member is not permitted to read." do
          let(:group_readable) { false }
          it { expect(subject).to be_blank }
          context "when user is administrator." do
            let(:admin) { true }
            it { expect(subject).to be_present }
          end
          context "when record is published" do
            let(:published){ true }
            it { expect(subject).to be_present }
          end
        end
      end
      context "when user does not belongs to record group." do
        let(:group_id) { another_group.id }
        let(:group_readable) { true }
        context "when guest is permitted to read." do
          let(:guest_readable) { true }
          it { expect(subject).to be_present }
        end
        context "when guest is not permitted to read." do
          let(:guest_readable) { false }
          it { expect(subject).to be_blank }
          context "when user is administrator." do
            let(:admin) { true }
            it { expect(subject).to be_present }
          end
        end
      end
    end
  end
end
