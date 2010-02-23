class ProgramRelationshipTypeMap < ActiveRecord::Base
  set_table_name "program_relationship_type_map"
  set_primary_key "program_relationship_type_map_id"
  include Openmrs
  belongs_to :program
  belongs_to :relationship_type
end
