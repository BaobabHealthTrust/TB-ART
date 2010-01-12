class ProgramWorkflowState < ActiveRecord::Base
  set_table_name "program_workflow_state"
  set_primary_key "program_workflow_state_id"
  include Openmrs
  belongs_to :program_workflow
  belongs_to :concept

  named_scope :active, :conditions => ['program_workflow_state.retired = 0']
end
