require 'spec_helper'
include ActionDispatch::TestProcess

describe AnalysesController do
  let(:user) { FactoryBot.create(:user) }
  before { sign_in user }

  describe "GET index" do
    let(:obj_1) { FactoryBot.create(:analysis, name: "hoge") }
    let(:obj_2) { FactoryBot.create(:analysis, name: "analysis_2") }
    let(:obj_3) { FactoryBot.create(:analysis, name: "analysis_3") }

    before do
      obj_1;obj_2;obj_3
      #get :index
    end
    context "without format" do
      before { get :index }
      it { expect(assigns(:analyses).count).to eq 3 }
    end

    context "with format json" do
      before do
        get :index, format: 'json'
      end
      it { expect(assigns(:analyses).count).to eq 3 }
      it { expect(response.body).to include("\"global_id\":") }
    end

    context "with format xml" do
      before do
        get :index, format: 'xml'
      end
      it { expect(assigns(:analyses).count).to eq 3 }
      it { expect(response.body).to eq([obj_3, obj_2, obj_1].to_xml)}
    end


    context "with format pml" do
      before do
        get :index, format: 'pml'
      end
      it { expect(assigns(:analyses).count).to eq 3 }
      it { expect(response.body).to eq([obj_3, obj_2, obj_1].to_pml)}
    end

    describe "with query" do
      context "without format" do
        before do
          get :index, params: { :q => {:name_cont => 'xxx'} }
        end
        it { expect(assigns(:analyses).count).to eq 0 }
      end
      context "with format json" do
        before do
          get :index, params: { :q => {:name_cont => 'xxx'}, :format => 'json' }
        end
        it { expect(response.body).to eq [].to_json }
      end
      context "with format xml" do
        before do
          get :index, params: { :q => {:name_cont => 'xxx'}, :format => 'xml' }
        end
        it { expect(response.body).to eq [].to_xml }
      end
      context "with format pml" do
        before do
          get :index, params: { :q => {:name_cont => 'xxx'}, :format => 'pml' }
        end
        it { expect(response.body).to eq [].to_pml }
      end


    end

  end

  describe "GET show" do
    let(:method){get :show, params: { id: id }}
    let(:obj) { FactoryBot.create(:analysis) }
    context "record found" do
      let(:id){obj.id}
      before { method }
      it{ expect(assigns(:analysis)).to eq obj }
    end
    context "record not found" do
      let(:id){0}
      it {expect{method}.to raise_error(ActiveRecord::RecordNotFound)}
    end
    context "with format pml", :current => true do
      let(:id){obj.id}
      before do
        #get :show, id: id, format: 'pml'
        get :show, params: { id: id ,format: :pml }

      end
      it{ expect(assigns(:analysis)).to eq obj }
      it { expect(response.body).to eq(obj.to_pml) }

    end
  end

  describe "GET edit" do
    let(:method){get :edit, params: {id: id}}
    let(:obj) { FactoryBot.create(:analysis) }
    context "record found" do
      let(:id){obj.id}
      before { method }
      it{ expect(assigns(:analysis)).to eq obj }
    end
    context "record not found" do
      let(:id){0}
      it {expect{method}.to raise_error(ActiveRecord::RecordNotFound)}
    end
  end

  describe "POST create" do
    let(:attributes) { {name: "obj_name"} }
    it { expect { post :create, params: { analysis: attributes } }.to change(Analysis, :count).by(1) }
    describe "assigns as @analysis" do
      before{ post :create, params: { analysis: attributes } }
      it{ expect(assigns(:analysis)).to be_persisted }
      it { expect(assigns(:analysis).name).to eq attributes[:name] }
    end
  end

  describe "PUT update" do
    let(:method){put :update, params: { id: id, analysis: attributes} }
    let(:obj) { FactoryBot.create(:analysis) }
    let(:attributes) { {name: "update_name"} }
    context "record found" do
      let(:id){obj.id}
      before { method }
      it { expect(assigns(:analysis)).to eq obj }
      it { expect(assigns(:analysis).name).to eq attributes[:name] }
    end
    context "record not found " do
      let(:id){0}
      it {expect{method}.to raise_error(ActiveRecord::RecordNotFound)}
    end
  end

  describe "POST bundle_edit" do
    let(:obj1) { FactoryBot.create(:analysis, name: "obj1") }
    let(:obj2) { FactoryBot.create(:analysis, name: "obj2") }
    let(:obj3) { FactoryBot.create(:analysis, name: "obj3") }
    let(:ids){[obj1.id,obj2.id]}
    before do
      obj1
      obj2
      obj3
      post :bundle_edit, params: { ids: ids }
    end
    it {expect(assigns(:analyses).include?(obj1)).to be_truthy}
    it {expect(assigns(:analyses).include?(obj2)).to be_truthy}
    it {expect(assigns(:analyses).include?(obj3)).to be_falsey}
  end

  describe "POST bundle_update" do
    let(:obj3name){"obj3"}
    let(:obj1) { FactoryBot.create(:analysis, name: "obj1") }
    let(:obj2) { FactoryBot.create(:analysis, name: "obj2") }
    let(:obj3) { FactoryBot.create(:analysis, name: obj3name) }
    let(:attributes) { {name: "update_name"} }
    let(:ids){[obj1.id,obj2.id]}
    before do
      obj1
      obj2
      obj3
      post :bundle_update, params: { ids: ids,analysis: attributes }
      obj1.reload
      obj2.reload
      obj3.reload
    end
    it {expect(obj1.name).to eq attributes[:name]}
    it {expect(obj2.name).to eq attributes[:name]}
    it {expect(obj3.name).to eq obj3name}
  end

  describe "GET picture" do
    let(:obj) { FactoryBot.create(:analysis) }
    before { get :picture, params: { id: obj.id }}
    it { expect(assigns(:analysis)).to eq obj }
  end

  describe "GET property" do
    let(:obj) { FactoryBot.create(:analysis) }
    before { get :property, params: { id: obj.id}}
    it { expect(assigns(:analysis)).to eq obj }
  end

  describe "POST import" do
    let(:data) { double(:upload_data) }
    before do
      allow(Analysis).to receive(:import_csv).with(data.to_s).and_return(import_result)
      post :import, params: { data: data }
    end
    context "import success" do
      let(:import_result) { true }
      it { expect(response).to redirect_to(analyses_path) }
    end
    context "import false" do
      let(:import_result) { false }
      it { expect(response).to render_template("import_invalid") }
    end
  end

  describe "GET table" do
    let(:obj) { FactoryBot.create(:analysis) }
    let(:obj2) { FactoryBot.create(:analysis) }
    let(:objs){ [obj,obj2]}
    before { get :table, params: { ids: objs.map {|obj| obj.id} }}
    it { expect(assigns(:analyses)).to eq objs }
    it { expect(response).to render_template("table") }
  end

  describe "GET castemls" do
    let(:obj) { FactoryBot.create(:analysis) }
    let(:obj2) { FactoryBot.create(:analysis) }
    let(:objs){ [obj,obj2]}
    let(:castemls){Analysis.to_castemls(objs)}
    after{get :castemls, params: {ids: objs.map {|obj| obj.id} }}
    it { expect(controller).to receive(:send_data).with(castemls, filename: "my-great-analysis.pml", type: "application/xml", disposition: "attached"){controller.head:no_content} }
  end

  describe "GET casteml", :current => true do
    let(:obj) { FactoryBot.create(:analysis) }
    let(:casteml){Analysis.to_castemls([obj])}
    after{get :casteml, params: {id: obj.id }}
    it { expect(controller).to receive(:send_data).with(casteml, filename: obj.global_id + ".pml", type: "application/xml", disposition: "attached"){controller.head:no_content} }
  end


end
