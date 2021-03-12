def fmt_long(obj)
  items = ["<#{obj.class.human_name.downcase}: #{obj.uniq_id}>"]
  items << "<link: specimen=#{obj.specimen_count} box=#{obj.box_count} analysis=#{obj.analysis_count} file=#{obj.file_count} bib=#{obj.bib_count} locality=#{obj.locality_count} point=#{obj.point_count}>"
  items << "<last-modifed: #{obj.updated_at}>"
  items << "<created: #{obj.created_at}>"
  items.join(" ")
end

namespace :record do
	namespace :dump do
		desc "Dump records in latex-mode"
		task :list => [:environment] do |t|
			boxes = Box.order(updated_at: :desc).to_a
			specimens = Specimen.order(updated_at: :desc).to_a
			bibs = Bib.order(updated_at: :desc).to_a

			physicalitems = boxes
			physicalitems.concat(specimens)

		  	output_path = ENV['output_path'] || "tmp/auto-specimen-list"
			#STDERR.puts "writing |#{output_path}|..."
		  	output = File.open(output_path,"w")
			physicalitems.each do |obj|
				output.puts "#{obj.latex_mode(:box)}"
				#puts "#{obj.full_name(:box)} #{fmt_long(obj)}" 
			end

			specimens.each do |obj|
				#puts "#{obj.full_name(:blood).gsub(/\//,"\\")} #{fmt_long(obj)}"
				output.puts "#{obj.latex_mode(:blood).gsub(/\//,"\\")}"
			end

			bibs.each do |obj|
				output.puts "#{obj.latex_mode(:blood)}"
			end
			output.close
		end

		desc "Dump records in pmlame"
		task :pmlame => [:environment] do |t|
		  records = Analysis.all
		  puts [ records.uniq.map {|item| item.to_pmlame } ].to_json
		  #p [ records.map {|item| item.build_pmlame([])}.flatten.uniq].to_json
		  #element_names = records.map()
		end

		desc "Dump records in bib-mode"
		task :bib => [:environment] do |t|
			items = Box.order(updated_at: :desc).to_a
			items.concat(Specimen.order(updated_at: :desc).to_a)
			items.concat(Bib.order(updated_at: :desc).to_a)
		  	output_path = ENV['output_path'] || "tmp/ref_dream.bib"
			#STDERR.puts "writing |#{output_path}|..."
		  	output = File.open(output_path,"w")

			items.each do |obj|
				output.puts "#{obj.to_bibtex}"
			end
			output.close

		end
	end
end
