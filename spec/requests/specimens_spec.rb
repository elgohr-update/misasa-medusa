# -*- coding: utf-8 -*-
require 'spec_helper'

describe "specimen" do
  before do
    login login_user
    create_data
    crate_search_columns
    visit specimens_path
  end
  let(:login_user) { FactoryBot.create(:user) }
  let(:create_data) {}
  let(:crate_search_columns) do
    FactoryBot.create(:search_column, user: login_user, datum_type: "Specimen", name: "name", display_name: "name", display_type: 2)
  end

  describe "specimen detail screen" do
    before { click_link(specimen.name, match: :first) }
    let(:create_data) do
      specimen.attachment_files << attachment_file
      specimen.create_record_property(user_id: login_user.id)
    end
    let(:specimen) { FactoryBot.create(:specimen, quantity: nil, quantity_unit: nil) }
    let(:attachment_file) { FactoryBot.create(:attachment_file, data_file_name: "file_name", data_content_type: data_type) }
    let(:data_type) { "image/jpeg" }

    describe "view spot" do
      context "picture-button is display" do
        before { click_link("picture-button") }
        let(:data_type) { "image/jpeg" }
        it "new spot label is properly displayed" do
          expect(page).to have_content("(link ID")
          #new spot with link(ID) feildのvalueオプションが存在しないため空であることの検証は行っていない
          expect(page).to have_link("record-property-search")
          expect(page).to have_button("add new spot")
        end
      end
      context "picture-button is not display" do
        context "no attachment_file" do
          let(:create_data) do
            specimen
            specimen.create_record_property(user_id: login_user.id)
          end
          it "picture-button not display" do
            expect(page).to have_no_link("picture-button")
          end
          it "new spot label not displayed" do
            expect(page).to have_no_content("new spot with link(ID")
            expect(page).to have_no_link("record-property-search")
            expect(page).to have_no_button("add new spot")
          end
        end
        context "attachment_file is pdf" do
          let(:data_type) { "application/pdf" }
          it "picture-button not display" do
            expect(page).to have_no_link("picture-button")
          end
          it "new spot label not displayed" do
            expect(page).to have_no_content("new spot with link(ID")
            expect(page).to have_no_link("record-property-search")
            expect(page).to have_no_button("add new spot")
          end
        end
      end

      describe "new spot" do
        pending "new spot新規作成時の実装が困難のためpending"
      end

      describe "thumbnail" do
        context "attachment_file is jpeg" do
          let(:data_type) { "image/jpeg" }
          before { click_link("picture-button") }
          it "image/jpeg is displayed" do
            expect(page).to have_css("img", count: 1)
          end
        end
        context "attachment_file is pdf" do
          let(:data_type) { "application/pdf" }
          it "picture-button not display" do
            expect(page).to have_no_link("picture-button")
          end
        end
      end
    end

    describe "dashboard tab" do
      before { click_link("dashboard") }
      describe "pdf icon" do
        context "data_content_type is pdf" do
          let(:data_type) { "application/pdf" }
          it "show icon" do
            expect(page).to have_link("file-#{attachment_file.id}-button")
          end
        end
        context "data_content_type is jpeg" do
          let(:data_type) { "image/jpeg" }
          it "do not show icon" do
            expect(page).not_to have_link("file-#{attachment_file.id}-button")
          end
        end
      end
    end

    describe "file tab" do
      before { click_link("file (1)") }
      describe "pdf icon" do
        context "data_content_type is pdf" do
          let(:data_type) { "application/pdf" }
          it "show icon" do
            expect(page).to have_link("file-#{attachment_file.id}-button")
          end
        end
        context "data_content_type is jpeg" do
          let(:data_type) { "image/jpeg" }
          it "do not show icon" do
            expect(page).not_to have_link("file-#{attachment_file.id}-button")
          end
        end
      end
    end
  end

end
