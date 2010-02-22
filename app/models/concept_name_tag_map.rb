class ConceptNameTagMap < ActiveRecord::Base
  set_table_name :concept_name_tag_map
  set_primary_key :concept_name_tag_map_id
  include Openmrs
  belongs_to :tag, :foreign_key => :concept_name_tag_id, :class_name => 'ConceptNameTag'
  belongs_to :concept_name_tag
  belongs_to :concept_name
end

