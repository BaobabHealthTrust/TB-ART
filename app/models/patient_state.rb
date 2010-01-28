class PatientState < ActiveRecord::Base
  set_table_name "patient_state"
  set_primary_key "patient_state_id"
  include Openmrs
  belongs_to :patient
  belongs_to :patient_program
  belongs_to :program_workflow_state, :foreign_key => :state, :class_name => 'ProgramWorkflowState'

  named_scope :active, :conditions => ['patient_state.voided = 0']
  named_scope :current, :conditions => ['start_date IS NOT NULL AND start_date >= ? AND (end_date IS NULL OR end_date > ?)', Time.now, Time.now]

  def after_save
    # If this is the only state and it is not initial, oh well
    # If this is a terminal state then close the program    
    patient_program.complete(end_date) if program_workflow_state.terminal != 0
  end
  
  def to_s
    s = program_workflow_state.concept.name.name
    s << " #{start_date.strftime('%d/%b/%Y')}" if start_date
    s << "-#{end_date.strftime('%d/%b/%Y')}" if end_date
    s
  end
end
