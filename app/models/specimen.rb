class Specimen < ActiveRecord::Base
  include HasRecordProperty
  include HasViewSpot
  include OutputPdf
  include OutputCsv
  include HasAttachmentFile
  include HasRecursive
  include HasPath

  acts_as_taggable
 #with_recursive

  has_many :analyses, before_remove: :delete_table_analysis
  has_many :children, -> { order(:name) }, class_name: "Specimen", foreign_key: :parent_id, dependent: :nullify
  has_many :specimens, class_name: "Specimen", foreign_key: :parent_id, dependent: :nullify  
  has_many :referrings, as: :referable, dependent: :destroy
  has_many :bibs, through: :referrings
  has_many :chemistries, through: :analyses
  has_many :specimen_custom_attributes, dependent: :destroy
  has_many :custom_attributes, through: :specimen_custom_attributes
  belongs_to :parent, class_name: "Specimen", foreign_key: :parent_id
  belongs_to :box
  belongs_to :place
  belongs_to :classification
  belongs_to :physical_form

  accepts_nested_attributes_for :specimen_custom_attributes

  validates :box, existence: true, allow_nil: true
  validates :place, existence: true, allow_nil: true
  validates :classification, existence: true, allow_nil: true
  validates :physical_form, existence: true, allow_nil: true
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :box_id }
  validate :parent_id_cannot_self_children, if: ->(specimen) { specimen.parent_id }
  validates :igsn, uniqueness: true, length: { maximum: 9 }, allow_nil: true
  validates :age_min, numericality: true, allow_nil: true
  validates :age_max, numericality: true, allow_nil: true
  validates :age_unit, presence: true, if: -> { age_min.present? || age_max.present? }
  validates :age_unit, length: { maximum: 255 }
  validates :size, length: { maximum: 255 }
  validates :size_unit, length: { maximum: 255 }
  validates :collector, length: { maximum: 255 }
  validates :collector_detail, length: { maximum: 255 }
  validates :collection_date_precision, length: { maximum: 255 }
  

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

  def ghost?
    quantity && quantity < 0
  end

  # def to_pml
  #   [self].to_pml
  # end

  def age_mean
    return unless ( age_min && age_max )
    (age_min + age_max) / 2.0
  end

  def age_error
    return unless ( age_min && age_max )
    (age_max - age_min) / 2.0
  end

  def age_in_text(opts = {})
    unit = opts[:unit] || self.age_unit
    scale = opts[:scale] || 0
    text = nil
    if age_mean && age_error
      #text = "#{age_mean}(#{age_error(opts)})"
      text = Alchemist.measure(self.age_mean, self.age_unit.to_sym).to(unit.to_sym).value.round(scale).to_s
      text += " (" + Alchemist.measure(self.age_error, self.age_unit.to_sym).to(unit.to_sym).value.round(scale).to_s + ")"
    elsif age_min
      text = ">" + Alchemist.measure(self.age_min, self.age_unit.to_sym).to(unit.to_sym).value.round(scale).to_s
    elsif age_max
      text = "<" + Alchemist.measure(self.age_max, self.age_unit.to_sym).to(unit.to_sym).value.round(scale).to_s      
    end
    return text
  end

  private

  def parent_id_cannot_self_children
    invalid_ids = descendants.map(&:id).unshift(self.id)
    if invalid_ids.include?(self.parent_id)
      errors.add(:parent_id, " make loop.")
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

end
