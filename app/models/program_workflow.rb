class ProgramWorkflow < ActiveRecord::Base
  set_table_name "program_workflow"
  set_primary_key "program_workflow_id"
  include Openmrs
  belongs_to :program
  belongs_to :concept

  named_scope :active, :conditions => ['program_workflow.retired = 0']
end
