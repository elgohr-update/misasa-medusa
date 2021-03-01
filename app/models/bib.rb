class Bib < ApplicationRecord
  include HasRecordProperty
  include HasViewSpot
  include OutputPdf
  include HasAttachmentFile

  LABEL_HEADER = ["Id", "Name", "Authors"]

  has_many :bib_authors, -> { order(:priority) }, before_add: :set_initial_position
  has_many :authors, -> { order(:priority) }, through: :bib_authors

  has_many :referrings, dependent: :destroy
  has_many :specimens, through: :referrings, source: :referable, source_type: "Specimen"
  has_many :places, through: :referrings, source: :referable, source_type: "Place"
  has_many :boxes, -> { order(:name) }, through: :referrings, source: :referable, source_type: "Box"
  has_many :analyses, through: :referrings, source: :referable, source_type: "Analysis"
  has_many :surfaces, through: :referrings, source: :referable, source_type: "Surface"
  has_many :tables, before_add: :take_over_specimens

  accepts_nested_attributes_for :bib_authors

  validates :name, presence: true, length: { maximum: 255 }
  validate :author_valid?, if: Proc.new{|bib| bib.authors.blank?}


  def related_spots
    sps = []
    # specimens.each do |specimen|
    #   sps.concat(specimen.related_spots)
    # end
#    sps = ancestors.map{|box| box.spot_links }.flatten || []
#    sps.concat(box.related_spots) if box
    sps
  end

  def as_json(options = {})
    super({:methods => [:author_ids, :global_id, :pmlame_ids]}.merge(options))
  end

  def specimen_places
    Place.eager_load(:specimens).where(specimens: {id: self.specimen_ids})
  end

  def table_specimens
    Specimen.eager_load(:table_specimens).where(tables: {id: self.table_ids})
  end

  def all_specimens
    self.specimens + self.table_specimens
  end

  def all_places
    rplaces = self.places + self.specimen_places
    rplaces
  end

  def all_spots
    surfaces.map(&:spots).flatten
  end

  def referrings_analyses
    ranalyses = self.analyses
    specimens.each do |specimen|
      (ranalyses = ranalyses + specimen.analyses) unless specimen.analyses.empty?
    end
    boxes.each do |box|
      (ranalyses = ranalyses + box.analyses) unless box.analyses.empty?
    end
    places.each do |place|
      (ranalyses = ranalyses + place.analyses) unless place.analyses.empty?
    end
    tables.each do |table|
      (ranalyses = ranalyses + table.analyses) unless table.analyses.empty?
    end
    #p ranalyses.to_sql
    ranalyses.uniq
  end

  def doi_link_url
    return unless doi
    "https://doi.org/#{doi}"
  end

  def primary_pdf_attachment_file
    pdf_files.first if pdf_files.present?
  end

  def build_label
    CSV.generate do |csv|
      csv << LABEL_HEADER
      csv << ["#{global_id}", "#{name}", "#{author_lists}"]
    end
  end

  def self.build_bundle_label(bibs)
    CSV.generate do |csv|
      csv << LABEL_HEADER
      bibs.each do |bib|
        csv << ["#{bib.global_id}", "#{bib.name}", "#{bib.author_lists}"]
      end
    end
  end

  def self.build_bundle_tex(bibs)
    bibs.map{|bib| bib.to_tex}.join(" ")
  end

  def to_tex
    if entry_type == "article"
#      tex = "\n@article{#{abbreviation.presence || global_id},\n#{article_tex},\n}"
      tex = "\n@article{#{global_id},\n#{article_tex},\n}"
    else
#      tex = "\n@misc{#{abbreviation.presence || global_id},\n#{misc_tex},\n}"
      tex = "\n@misc{#{global_id},\n#{misc_tex},\n}"
    end
    return tex
  end

  def article_tex
    bib_array = []
    bib_array << "\tauthor = \"#{author_lists}\""
    bib_array << "\ttitle = \"#{name}\""
    if journal == "DREAM Digital Document"
      bib_array << "\tjournal = {\\href{#{dream_url}}{#{journal}}}"
    else
      bib_array << "\tjournal = \"#{journal}\""
    end
    bib_array << "\tyear = \"#{year}\""
    bib_array << "\tnumber = \"#{number}\"" if number.present?
    bib_array << "\tmonth = \"#{month}\"" if month.present?
    bib_array << "\tvolume = \"#{volume}\"" if volume.present?
    bib_array << "\tpages = \"#{pages}\"" if pages.present?
    bib_array << "\tnote = \"#{note}\"" if note.present?
    bib_array << "\tdoi = \"#{doi}\"" if doi.present?
    bib_array << "\tkey = \"#{key}\"" if key.present?
    bib_array.join(",\n")
  end

  def misc_tex
    bib_array = []
    bib_array << "\tauthor = \"#{author_lists}\""
    bib_array << "\ttitle = \"#{name}\""
    bib_array << "\tnumber = \"#{number}\"" if number.present?
    bib_array << "\tmonth = \"#{month}\"" if month.present?
    bib_array << "\tjournal = \"#{journal}\"" if journal.present?
    bib_array << "\tvolume = \"#{volume}\"" if volume.present?
    bib_array << "\tpages = \"#{pages}\"" if pages.present?
    bib_array << "\tyear = \"#{year}\"" if year.present?
    bib_array << "\tnote = \"#{note}\"" if note.present?
    bib_array << "\tdoi = \"#{doi}\"" if doi.present?
    bib_array << "\tkey = \"#{key}\"" if key.present?
    bib_array.join(",\n")
  end

  def author_lists
    authors.pluck(:name).join(" and ")
  end

  def to_html
    html = authors.first.name
    #if authors.size > 2
    #  html = authors[0].name + " et al."
    #else
    #  html = authors.pluck(:name).join(" and ")
    #end
    html += " (#{year})" if year.present?
    html += " #{name}" if name.present?
    html += ", <i>#{journal}</i>" if journal.present?
    html += ", <b>#{volume}</b>" if volume.present?
    html += ", #{pages}" if pages.present?
    return "#{html}."
  end

  def publish!
    objs = [self]
    objs.concat(self.boxes)
    objs.concat(self.places)
    objs.each do |obj|
      obj.published = true
      obj.save
    end

    objs_r = []
    objs_r.concat(self.specimens)
    objs_r.concat(self.analyses)
    objs_r.concat(self.tables)
    objs_r.each do |obj|
      obj.publish!
    end
  end

  def pml_elements
    self.referrings_analyses
  end

  private

  def pdf_files
    if attachment_files.present?
      attachment_files.order("updated_at desc").select {|file| file.pdf? }
    end
  end

  def author_valid?
    errors.add(:authors, :blank, message: "can't be blank")
  end

  def set_initial_position(bib_author)
    priority = (bib_authors.maximum(:priority) || 0) + 1
    bib_author.update_attribute(:priority, priority)
  end

  def take_over_specimens(table)
    return if table.ignore_take_over_specimen?
    table.specimens = specimens
  end


end
