require 'spec_helper'

describe DevicesController do
  let(:user) { FactoryBot.create(:user) }
  before { sign_in user }

  describe "GET index" do
    let(:device_1) { FactoryBot.create(:device, name: "hoge") }
    let(:device_2) { FactoryBot.create(:device, name: "device_2") }
    let(:device_3) { FactoryBot.create(:device, name: "device_3") }
    let(:params) { {q: query, page: 2, per_page: 1} }
    before do
      device_1;device_2;device_3
      get :index, params: params
    end
    context "sort condition is present" do
      let(:query) { {"name_cont" => "device", "s" => "name DESC"} }
      it { expect(assigns(:devices).to_a).to eq [device_3, device_2] }
    end
    context "sort condition is present" do
      let(:query) { {"name_cont" => "device", "s" => "name"} }
      it { expect(assigns(:devices).to_a).to eq [device_2, device_3] }
    end

    context "sort condition is nil" do
      let(:query) { {} }
      it { expect(assigns(:devices).to_a).to eq [device_1, device_2, device_3] }
    end
  end

  # This "GET show" has no html.
  describe "GET show" do
    let(:device) { FactoryBot.create(:device) }
    before do
      device
      get :show, params: { id: device.id, format: :json }
    end
    it { expect(response.body).to eq(device.to_json) }
  end

  describe "GET edit" do
    let(:device) { FactoryBot.create(:device) }
    before do
      device
      get :edit, params: { id: device.id }
    end
    it { expect(assigns(:device)).to eq device }
  end

  describe "POST create" do
    describe "with valid attributes" do
      let(:attributes) { {name: "device_name"} }
      it { expect { post :create, params: { device: attributes }}.to change(Device, :count).by(1) }
      it "assigns a newly created device as @device" do
        post :create, params: { device: attributes }
        expect(assigns(:device)).to be_persisted
        expect(assigns(:device).name).to eq(attributes[:name])
      end
    end
    describe "with invalid attributes" do
      let(:attributes) { {name: ""} }
      before { allow_any_instance_of(Device).to receive(:save).and_return(false) }
      it { expect { post :create, params: { device: attributes }}.not_to change(Device, :count) }
      it "assigns a newly but unsaved device as @device" do
        post :create, params: { device: attributes }
        expect(assigns(:device)).to be_new_record
        expect(assigns(:device).name).to eq(attributes[:name])
      end
    end
  end

  describe "PUT update" do
    let(:device) { FactoryBot.create(:device, name: "device") }
    before do
      device
      put :update, params: { id: device.id, device: attributes }
    end
    describe "with valid attributes" do
      let(:attributes) { {name: "update_name"} }
      it { expect(assigns(:device)).to eq device }
      it { expect(assigns(:device).name).to eq attributes[:name] }
      it { expect(response).to redirect_to(devices_path) }
    end
    describe "with invalid attributes" do
      let(:attributes) { {name: ""} }
      before { allow(device).to receive(:update).and_return(false) }
      it { expect(assigns(:device)).to eq device }
      it { expect(assigns(:device).name).to eq attributes[:name] }
      it { expect(response).to render_template("edit") }
    end
  end

  describe "DELETE destroy" do
    let(:device) { FactoryBot.create(:device, name: "device") }
    before { device }
    it { expect { delete :destroy, params: { id: device.id }}.to change(Device, :count).by(-1) }
  end

end
