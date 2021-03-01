require "spec_helper"

describe "TableSpecimen" do

  describe "before_create" do
    describe "assign_position" do
      let(:table_specimen) { FactoryBot.create(:table_specimen, position: nil, table: table) }
      let(:table) { FactoryBot.create(:table) }
      subject { table_specimen.position }
      context "not exists other table_specimen record" do
        before do
          table_specimen
          table_specimen.reload
        end
        it { expect(subject).to eq 1 }
      end
      context "exists other table_specimen record" do
        let(:other_table_specimen_1) { FactoryBot.create(:table_specimen, position: 10, table: table) }
        let(:other_table_specimen_2) { FactoryBot.create(:table_specimen, position: 20, table: table_2) }
        let(:table_2) { FactoryBot.create(:table) }
        before do
          other_table_specimen_1
          other_table_specimen_2
          table_specimen
          table_specimen.reload
        end
        it { expect(subject).to eq(other_table_specimen_1.position + 1) }
      end
    end
    
    describe "create_table_analyses" do
      let(:table_specimen) { FactoryBot.create(:table_specimen, specimen: specimen, table: table) }
      let(:specimen) { FactoryBot.create(:specimen) }
      let(:sub_specimen){  FactoryBot.create(:specimen, parent_id: specimen.id) }
      let(:table) { FactoryBot.create(:table) }
      let(:analysis_1) { FactoryBot.create(:analysis, specimen: specimen) }
      let(:analysis_2) { FactoryBot.create(:analysis, specimen: specimen) }
      let(:analysis_3) { FactoryBot.create(:analysis, specimen: sub_specimen) }
      let(:analysis_4) { FactoryBot.create(:analysis, specimen: sub_specimen) }

      before do
        analysis_1
        analysis_2
        analysis_3
        analysis_4
      end
      it { expect { table_specimen }.to change(TableAnalysis, :count).from(0).to(4) }
      describe "TableAnalysis record" do
        before { table_specimen }
        it { expect(TableAnalysis.pluck(:table_id)).to eq [table.id, table.id,table.id, table.id] }
        it { expect(TableAnalysis.pluck(:specimen_id)).to eq [specimen.id, specimen.id, specimen.id, specimen.id] }
        it { expect(TableAnalysis.pluck(:analysis_id)).to include(analysis_1.id, analysis_2.id,analysis_3.id, analysis_4.id) }
        it { expect(TableAnalysis.pluck(:priority)).to include(0, 1, 2, 3) }
      end
    end
  end

end

