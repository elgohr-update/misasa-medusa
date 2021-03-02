class SpecimenQuantity < ApplicationRecord
  include HasQuantity

  belongs_to :specimen, touch: true
  belongs_to :divide
  has_one :after_divide, foreign_key: "before_specimen_quantity_id", class_name: "Divide"

  validates :quantity, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  def self.point(divide, quantity, quantity_str)
    h = {}
    h[:id] = divide.id
    h[:x] = divide.chart_updated_at
    h[:y] = quantity
    h[:date_str] = divide.updated_at_str
    h[:quantity_str] = quantity_str
    h[:before_specimen_name] = divide.before_specimen.try(:name) if divide.divide_flg
    h[:before_specimen] = divide.before_specimen if divide.divide_flg
    h[:divide_flg] = divide.divide_flg
    h[:comment] = divide.log
    h[:parent_specimen] = divide.parent_specimen
    h[:child_specimens] = divide.child_specimens
    h
  end

  def point
    self.class.point(self.divide, decimal_quantity.to_f, string_quantity)
  end
end
