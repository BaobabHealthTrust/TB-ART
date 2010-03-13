class RegimenCriteria < ActiveRecord::Base
  set_table_name "regimen_criteria"
  set_primary_key "regimen_criteria_id"
  include Openmrs
  belongs_to :concept
  belongs_to :program
  has_many :regimens
  named_scope :program, lambda {|program_id| {:conditions => {:program_id => program_id}}}
  named_scope :criteria, lambda {|weight| {:conditions => ['min_weight <= ? AND max_weight >= ?', weight, weight]} unless weight.blank?}
  named_scope :active, :conditions => ['regimen_criteria.retired = 0']
end