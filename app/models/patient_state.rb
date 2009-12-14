class PatientState < ActiveRecord::Base
  set_table_name "patient_state"
  set_primary_key "patient_state_id"
  include Openmrs
  belongs_to :patient
  belongs_to :patient_program

  named_scope :active, :conditions => ['patient_state.voided = 0']
  named_scope :current, :conditions => ['start_date IS NOT NULL AND start_date >= ? AND (end_date IS NULL OR end_date > ?)', Time.now, Time.now]
end
