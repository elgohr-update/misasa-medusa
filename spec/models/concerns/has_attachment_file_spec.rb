require "spec_helper"

class HasAttachmentFileSpec < ApplicationRecord
  include HasAttachmentFile
end

class HasAttachmentFileSpecMigration < ActiveRecord::Migration[4.2]
  def self.up
    create_table :has_attachment_file_specs do |t|
      t.string :name
    end
  end
  def self.down
    drop_table :has_attachment_file_specs
  end
end

describe HasAttachmentFile do
  let(:klass) { HasAttachmentFileSpec }
  let(:migration) { HasAttachmentFileSpecMigration }

  before { migration.suppress_messages { migration.up } }
  after { migration.suppress_messages { migration.down } }
  
  describe "control attachments order", :current => true do
    let(:obj) { klass.create(name: "foo") }
    let(:attachment_file_1) { FactoryBot.create(:attachment_file, data_file_name: "file_name_1", data_content_type: data_content_type_1) }
    let(:attachment_file_2) { FactoryBot.create(:attachment_file, data_file_name: "file_name_2", data_content_type: data_content_type_2) }
    let(:attachment_file_3) { FactoryBot.create(:attachment_file, data_file_name: "file_name_3", data_content_type: data_content_type_3) }
    let(:data_content_type_1) { data_content_type_2 }
    let(:data_content_type_2) { "application/pdf" }
    let(:data_content_type_3) { "image/jpeg" }
    before do
      obj.attachment_files << attachment_file_1
      obj.attachment_files << attachment_file_2
      obj.attachment_files << attachment_file_3
    end
    it { expect(obj.attachment_files.first).to be_eql(attachment_file_1) }
    context "after move" do
      before do
        attaching = obj.attachings.where(attachment_file_id: attachment_file_3.id)[0]
        attaching.move_to_top
      end
      it { expect(obj.attachment_files.first).to be_eql(attachment_file_3) }
    end
  end

  describe "attachment_pdf_files" do
    subject { obj.attachment_pdf_files }
    let(:obj) { klass.create(name: "foo") }
    let(:attachment_file_1) { FactoryBot.create(:attachment_file, data_file_name: "file_name_1", data_content_type: data_content_type_1) }
    let(:attachment_file_2) { FactoryBot.create(:attachment_file, data_file_name: "file_name_2", data_content_type: data_content_type_2) }
    let(:attachment_file_3) { FactoryBot.create(:attachment_file, data_file_name: "file_name_3", data_content_type: data_content_type_3) }
    before do
      obj.attachment_files << attachment_file_1
      obj.attachment_files << attachment_file_2
      obj.attachment_files << attachment_file_3
    end
    context "data_content_type is pdf" do
      let(:data_content_type_1) { data_content_type_2 }
      let(:data_content_type_2) { "application/pdf" }
      let(:data_content_type_3) { "image/jpeg" }
      it { expect(subject).to be_present }
      it { expect(subject).to include(attachment_file_1) }
      it { expect(subject).to include(attachment_file_2) }
    end
    context "data_content_type is jpeg" do
      let(:data_content_type_1) { data_content_type_2 }
      let(:data_content_type_2) { data_content_type_3 }
      let(:data_content_type_3) { "image/jpeg" }
      it { expect(subject).to be_blank }
    end
  end
  
  describe "attachment_image_files" do
    subject { obj.attachment_image_files }
    let(:obj) { klass.create(name: "foo") }
    let(:attachment_file_1) { FactoryBot.create(:attachment_file, data_file_name: "file_name_1", data_content_type: data_content_type_1) }
    let(:attachment_file_2) { FactoryBot.create(:attachment_file, data_file_name: "file_name_2", data_content_type: data_content_type_2) }
    let(:attachment_file_3) { FactoryBot.create(:attachment_file, data_file_name: "file_name_3", data_content_type: data_content_type_3) }
    before do
      obj.attachment_files << attachment_file_1
      obj.attachment_files << attachment_file_2
      obj.attachment_files << attachment_file_3 
    end
    context "data_content_type is jpeg" do
      let(:data_content_type_1) { data_content_type_2 }
      let(:data_content_type_2) { "image/jpeg" }
      let(:data_content_type_3) { "application/pdf" }
      it { expect(subject).to be_present }
      it { expect(subject).to include(attachment_file_2) }
      it { expect(subject).to include(attachment_file_1) }
    end
    context "data_content_type is pdf" do
      let(:data_content_type_1) { data_content_type_2 }
      let(:data_content_type_2) { data_content_type_3 }
      let(:data_content_type_3) { "application/pdf" }
      it { expect(subject).to be_blank }
    end
  end
  
end
