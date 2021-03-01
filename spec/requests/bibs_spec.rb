require 'spec_helper'

describe "bib master" do
  before do
    login login_user
    create_data
    visit bibs_path
  end
  let(:login_user) { FactoryBot.create(:user) }
  let(:create_data) {}
  
  describe "bib detail screen" do
    before { click_link(bib.name) }
    let(:create_data) do
      bib.attachment_files << attachment_file 
      bib.create_record_property(user_id: login_user.id) 
    end
    let(:bib) { FactoryBot.create(:bib) }
    let(:attachment_file) { FactoryBot.create(:attachment_file, data_file_name: "file_name", data_content_type: data_type) }
    
    describe "view spot" do
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

    describe "at-a-glance tab" do
      before { click_link("at-a-glance") }
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
