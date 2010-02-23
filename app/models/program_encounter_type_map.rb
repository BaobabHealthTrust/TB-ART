class ProgramEncounterTypeMap < ActiveRecord::Base
  set_table_name "program_encounter_type_map"
  set_primary_key "program_encounter_type_map_id"
  include Openmrs
  belongs_to :program
  belongs_to :encounter_type
end
