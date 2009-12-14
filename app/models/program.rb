class Program < ActiveRecord::Base
  set_table_name "program"
  set_primary_key "program_id"
  include Openmrs
  belongs_to :concept
  has_many :patient_programs

  named_scope :active, :conditions => ['program.retired = 0']
end
