# -*- coding: utf-8 -*-
class Specimen < ActiveRecord::Base
  include HasRecordProperty
  include HasViewSpot
  include OutputPdf
  include OutputCsv
  include HasAttachmentFile
  include HasRecursive
  include HasPath
  include HasQuantity

  attr_accessor :divide_flg
  attr_accessor :comment

  acts_as_taggable
 #with_recursive

  after_initialize :calculate_rel_age
  before_save :build_specimen_quantity,
    if: -> (s) { !s.divide_flg && (s.quantity_changed? || s.quantity_unit_was.presence != s.quantity_unit.presence) }
  before_save :build_age,
    if: -> (s) { s.instance_variable_defined?(:@age_mean) }
  has_many :analyses, before_remove: :delete_table_analysis
  has_many :children, -> { order(:name) }, class_name: "Specimen", foreign_key: :parent_id, dependent: :nullify
  has_many :specimens, class_name: "Specimen", foreign_key: :parent_id, dependent: :nullify
  has_many :referrings, as: :referable, dependent: :destroy
  has_many :bibs, through: :referrings
  has_many :specimen_surfaces, dependent: :destroy
  has_many :surfaces, through: :specimen_surfaces
  has_many :chemistries, through: :analyses
  has_many :specimen_custom_attributes, dependent: :destroy
  has_many :custom_attributes, through: :specimen_custom_attributes
  has_many :specimen_quantities
  belongs_to :parent, class_name: "Specimen", foreign_key: :parent_id
  belongs_to :box
  belongs_to :place
  belongs_to :classification
  belongs_to :physical_form

  delegate :name, to: :physical_form, prefix: true, allow_nil: true

  accepts_nested_attributes_for :specimen_quantities
  accepts_nested_attributes_for :specimen_custom_attributes
  accepts_nested_attributes_for :children

  validates :box, existence: true, allow_nil: true
  validates :place, existence: true, allow_nil: true
  validates :classification, existence: true, allow_nil: true
  validates :physical_form, existence: true, allow_nil: true
  #validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :box_id }
  validates :name, presence: true, length: { maximum: 255 }
  validate :parent_id_cannot_self_children, if: ->(specimen) { specimen.parent_id }
  validates :igsn, uniqueness: true, length: { maximum: 9 }, allow_nil: true, allow_blank: true
  validates :abs_age, numericality: { only_integer: true }, allow_nil: true
  validates :age_min, numericality: true, allow_nil: true
  validates :age_max, numericality: true, allow_nil: true
  validates :age_unit, presence: true, if: -> { age_min.present? || age_max.present? }
  validates :age_unit, length: { maximum: 255 }
  validates :quantity, presence: { if: -> { quantity_unit.present? } }
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :quantity_unit, presence: { if: -> { quantity.present? } }
  validate :quantity_unit_exists
  validates :size, length: { maximum: 255 }
  validates :size_unit, length: { maximum: 255 }
  validates :collector, length: { maximum: 255 }
  validates :collector_detail, length: { maximum: 255 }
  validates :collection_date_precision, length: { maximum: 255 }
  validate :status_is_nomal, on: :divide

  def self.build_bundle_list(objs)
    CSV.generate do |csv|
      csv << ["Id", "Name", "IGSN", "Parent-Id", "Parent-Name", "Quantity", "Physical-Form", "Classification","Description","Group","User","Updated-at","Created-at"]
      objs.each do |obj|
        csv << ["#{obj.global_id}", "#{obj.name}", "#{obj.igsn}", "#{obj.parent.try!(:global_id)}","#{obj.parent.try!(:name)}","#{obj.quantity_with_unit}", "#{obj.physical_form.try!(:name)}", "#{obj.classification.try!(:full_name)}","#{obj.description}","#{obj.group.try!(:name)}","#{obj.user.try!(:username)}","#{obj.updated_at}","#{obj.created_at}"]
      end
    end
  end

  def root_with_includes
    Specimen.includes({children: [:record_property]}).find(root.id)
  end

  def families_with_includes
    Specimen.includes(:record_property, {children:[:record_property]}, {analyses:[:record_property, :chemistries]}, {bibs:[:record_property]}, {attachment_files:[:record_property]}).where(id: family_ids)
  end

  def as_json(options = {})
    super({ methods: [:global_id, :physical_form_name, :primary_file_thumbnail_path, :pmlame_ids] }.merge(options))
  end

  def status
    return unless record_property
    if record_property.disposed
      Status::DISPOSAL
    elsif record_property.lost
      Status::LOSS
    elsif quantity.blank? || decimal_quantity < 0
      Status::UNDETERMINED_QUANTITY
    elsif decimal_quantity_was.zero?
      Status::DISAPPEARANCE
    else
      Status::NORMAL
    end
  end

  def publish!
    specimens = [self]
    specimens.concat(self.ancestors)
    boxes = []
    places = []
    attachment_files = []
    specimens.each do |specimen|
      attachment_files.concat(specimen.attachment_files) if specimen.attachment_files
      if specimen.box
        boxes << specimen.box
        boxes.concat(specimen.box.ancestors) if specimen.box
      end
      if specimen.place
        place = specimen.place
        places << place
        attachment_files.concat(place.attachment_files) if place.attachment_files
      end
    end
    boxes.each do |box|
      attachment_files.concat(box.attachment_files)
    end
    objs = []
    objs.concat(specimens)
    objs.concat(boxes)
    objs.concat(places)
    objs.concat(attachment_files)
    objs.each do |obj|
      obj.published = true
      obj.save
    end
    self.surfaces.each do |surface|
      surface.publish!
    end
  end

  def set_specimen_custom_attributes
    ids = specimen_custom_attributes.pluck('DISTINCT custom_attribute_id')
    if ids.size == CustomAttribute.count
      specimen_custom_attributes.joins(:custom_attribute).includes(:custom_attribute).order("custom_attributes.name")
    else
      (CustomAttribute.pluck(:id) - ids).each do |custom_attribute_id|
        specimen_custom_attributes.build(custom_attribute_id: custom_attribute_id)
      end
      specimen_custom_attributes.sort_by {|sca| sca.custom_attribute.name }
    end
  end

  def full_analyses
    Analysis.includes(:chemistries, :record_property, :device, {specimen: [:record_property]}).where(specimen_id: self_and_descendants)
  end

  def full_surfaces
    Surface.includes(:record_property).where(id: SpecimenSurface.where(specimen_id: self_and_descendants).pluck(:surface_id))
  end

  def full_bibs
    Bib.includes(:record_property, :tables, :referrings).where(id: Referring.where(referable_type: "Specimen").where(referable_id: self_and_descendants).pluck(:bib_id))
  end

  def full_tables
    Table.where(id: TableSpecimen.where(specimen_id: family_ids).pluck(:table_id)).includes({table_specimens: [:specimen]}).order(:caption)
  end

  def whole_family_analyses
    Analysis.where(specimen_id: families)
  end

  def candidate_surfaces
    sfs = []
    attachment_image_files.each do |image|
      sfs.concat(image.surfaces) if image.surfaces
    end
    sfs.compact.uniq
  end

  def ghost?
    quantity && quantity <= 0 || [Status::DISAPPEARANCE, Status::DISPOSAL, Status::LOSS].include?(status)
  end

  def related_spots
    sps = ancestors.map{|box| box.spot_links }.flatten || []
    sps.concat(box.related_spots) if box
    sps
  end

  # def to_pml
  #   [self].to_pml
  # end

  def abs_age_text
    return unless abs_age
    "#{era} #{abs_age.abs}"
  end

  def era
    (abs_age < 0) ? "BC" : "AD"
  end

  def age_mean
    return unless ( age_min && age_max )
    (age_min + age_max) / 2.0
  end

  def age_mean=(age)
    if age.blank?
      @age_mean = nil
    else
      @age_mean = age.to_f
    end
  end

  def age_error
    return unless ( age_min && age_max )
    (age_max - age_min) / 2.0
  end

  def age_error=(error)
    if error.blank?
      @age_error = nil
    else
      @age_error = error.to_f
    end
  end

  def rage_unit
    ans_and_self = [self]
    ans_and_self.concat(ancestors.reverse) unless ancestors.empty?
    rau = nil
    ans_and_self.each do |s|
      if s.age_unit
        rau = s.age_unit
        break
      end
    end
    rau
  end

  def rage_in_text(opts = {})
    ans_and_self = [self]
    ans_and_self.concat(ancestors.reverse) unless ancestors.empty?
    ra = nil
    ans_and_self.each do |s|
      if s.age_unit
        ra = s.age_in_text
        break
      end
    end
    ra
  end

  def age_in_text(opts = {:with_error => true})
    age_unit = "a"
    age_unit = self.age_unit unless self.age_unit.blank?
    unit = opts[:unit] || age_unit
    scale = opts[:scale] || 3
    text = nil
    if age_mean && age_error
      #text = "#{age_mean}(#{age_error(opts)})"
      text = Alchemist.measure(self.age_mean, age_unit.to_sym).to(unit.to_sym).value.round(scale).to_s
      text += " (" + Alchemist.measure(self.age_error, age_unit.to_sym).to(unit.to_sym).value.round(scale).to_s + ")" if opts[:with_error]
    elsif age_min
      text = ">" + Alchemist.measure(self.age_min, age_unit.to_sym).to(unit.to_sym).value.round(scale).to_s
    elsif age_max
      text = "<" + Alchemist.measure(self.age_max, age_unit.to_sym).to(unit.to_sym).value.round(scale).to_s
    end
    text += " #{unit}" if text && opts[:with_unit]
    return text
  end

  def rplace
    ans_and_self = [self]
    ans_and_self.concat(ancestors.reverse) unless ancestors.empty?
    rp = nil
    ans_and_self.each do |s|
      if s.place
        rp = s.place
        break
      end
    end
    rp
  end

  def relatives_for_tree
    list = [self].concat(children)
    #list = [root].concat(root.children)
    ans = ancestors
    depth = ans.size
    if depth > 0
      list.concat(siblings)
      list.concat(ans)
      ans.each do |an|
        list.concat(an.siblings)
      end
    # elsif depth > 1
    #   list.concat(ans[1].descendants)
    end
    list.uniq!
    families.select{|e| list.include?(e) }
  end

  def quantity_history_with_current
    time_str = Time.now + 9.hours
    time_int = time_str.to_i * 1000
    dup = quantity_history.clone
    dup.each do |key, oval|
      val = oval.dup
      dup[key] = val
    end

    dup.each do |key, val|
      #val = oval.dup
      last_hash = val[-1].dup
      last_hash[:x] = time_int
      last_hash[:date_str] = 'now'
      last_hash[:id] = nil
      last_hash[:log] = nil
      val.push(last_hash)
    end
    dup
  end

  def quantity_history
    return @quantity_history if @quantity_history
    divides = Divide.includes(:specimen_quantities).specimen_id_is(self_and_descendants.map(&:id))
    total_hash = {}
    h = Hash.new {|h, k| h[k] = Array.new }
    @quantity_history = divides.each_with_object(h) do |divide, hash|
      divide.specimen_quantities.each do |specimen_quantity|
        hash[specimen_quantity.specimen_id] << specimen_quantity.point
        total_hash[specimen_quantity.specimen_id] = specimen_quantity.decimal_quantity
      end
      total_val = total_hash.values.compact.sum
      hash[0] << SpecimenQuantity.point(divide, total_val.to_f, Quantity.string_quantity(total_val, "g"))
    end
    # last_divide = divides.last
    # @quantity_history.each do |key, quantity_line|
    #   if quantity_line.last[:id] != last_divide.id
    #     quantity_line << SpecimenQuantity.point(last_divide, quantity_line.last[:y], quantity_line.last[:quantity_str])
    #   end
    # end
    @quantity_history
  end

  def divided_parent_quantity
    children_decimal_quantity = new_children.inject(0.to_d) do |sum, specimen|
      sum + specimen.decimal_quantity
    end
    decimal_quantity_was - children_decimal_quantity
  end

  def divided_loss
    divided_parent_quantity - decimal_quantity
  end

  def divide_save
    self.divide_flg = true
    ActiveRecord::Base.transaction do
      divide = build_divide
      divide.save!
      build_specimen_quantity(divide)
      new_children.each do |child|
        child.divide_flg = true
        child.build_specimen_quantity(divide)
      end
      save!
    end
  end

  def build_specimen_quantity(divide = build_divide)
    specimen_quantity = specimen_quantities.build
    specimen_quantity.quantity = quantity
    specimen_quantity.quantity_unit = quantity_unit
    specimen_quantity.divide = divide
    specimen_quantity
  end

  def build_age
    if @age_mean
      error = @age_error || 0.0
      self.age_min = @age_mean - error
      self.age_max = @age_mean + error
    end
  end
  private

  def new_children
    children.select(&:new_record?).to_a
  end

  def build_divide
    divide = Divide.new
    divide.before_specimen_quantity = specimen_quantities.last
    divide.divide_flg = divide_flg || false
    divide.log = build_log
    divide
  end

  def build_log
    if divide_flg
      comment
    elsif string_quantity_was.blank?
      "Quantity of #{name} was set to #{string_quantity}"
    elsif string_quantity.blank?
      "Quantity of #{name} was deleted"
    else
      "Quantity of #{name} was changed from #{string_quantity_was} to #{string_quantity}"
    end
  end

  def parent_id_cannot_self_children
    invalid_ids = descendants.map(&:id).unshift(self.id)
    if invalid_ids.include?(self.parent_id)
      errors.add(:parent_id, " make loop.")
    end
  end

  def status_is_nomal
    unless [Status::NORMAL, Status::UNDETERMINED_QUANTITY].include?(status)
      errors.add(:status, " is not normal")
    end
  end

  def path_changed?
    box_id_changed?
  end

  def path_ids
    box.present? ? box.ancestors + [box.id] : []
  end

  def delete_table_analysis(analysis)
    TableAnalysis.delete_all(analysis_id: analysis.id, specimen_id: self.id)
  end

  def calculate_rel_age
    return unless abs_age
    rel_age = Time.current.year - abs_age
    digits = Math.log10(rel_age.abs).to_i + 1
    self.age_unit = case digits
                    when 1..3; "a"
                    when 4..6; "ka"
                    when 7..9; "Ma"
                    else "Ga"
                    end
    self.age_min = self.age_max = Alchemist.measure(rel_age, :a).to(age_unit.to_sym).value.round(2)
  end
end
