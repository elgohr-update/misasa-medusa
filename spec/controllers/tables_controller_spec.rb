require 'spec_helper'
include ActionDispatch::TestProcess

describe TablesController do
  before { sign_in user }
  let(:user) { FactoryBot.create(:user) }
  let(:table) { FactoryBot.create(:table) }

  describe "GET index" do
    before { get :index }
    it { expect(response).to redirect_to(bibs_path) }
  end

  describe "GET show" do
    context "format no specify" do
      before { get :show, params: { id: table.id }}
      it { expect(assigns(:table)).to eq table }
    end
    context "format csv" do
      before { get :show, params: { id: table.id, format: :csv }}
      it { expect(assigns(:table)).to eq table }
      it { expect(response.headers.has_value?("text/csv")).to eq true }
      it do
        flag = response.headers.values.any? {|val| val.include?("filename=\"#{table.caption}.csv\"") }
        expect(flag).to eq true
      end
    end
    context "format pml", :current => true do
      before { get :show, params: { id: table.id, format: :pml }}
      it do
        expect(response.headers.has_value?("application/xml; charset=utf-8")).to eq true
      end
      it do
        flag = response.body == [table].to_pml
        expect(flag).to eq true
      end
    end
  end

  describe "GET edit" do
    before { get :edit, params: { id: table.id }}
    it{ expect(assigns(:table)).to eq table }
  end

  describe "PUT update" do
    before do
      table
      put :update, params: { id: table.id, table: attributes }
    end
    let(:attributes) { {description: "update_description"} }
    it { expect(assigns(:table)).to eq table }
    it { expect(assigns(:table).description).to eq attributes[:description] }
  end

  describe "GET property" do
    before { get :property, params: { id: table.id }}
    it { expect(assigns(:table)).to eq table }
  end

  describe "DELETE destroy" do
    before { table }
    it { expect { delete :destroy, params: { id: table.id }}.to change(Table, :count).by(-1) }
  end

end
