class PatientState < ActiveRecord::Base
  set_table_name "patient_state"
  set_primary_key "patient_state_id"
  include Openmrs
  belongs_to :patient
  belongs_to :patient_program
  belongs_to :patient_state, :foreign_key => :state, :class_name => 'ProgramWorkflowState'

  named_scope :active, :conditions => ['patient_state.voided = 0']
  named_scope :current, :conditions => ['start_date IS NOT NULL AND start_date >= ? AND (end_date IS NULL OR end_date > ?)', Time.now, Time.now]
  
  def to_s
    s = patient_state.concept.name.name
    s << " #{start_date.strftime('%d/%b/%Y')}" if start_date
    s << "-#{end_date.strftime('%d/%b/%Y')}" if end_date
    s
  end
end
