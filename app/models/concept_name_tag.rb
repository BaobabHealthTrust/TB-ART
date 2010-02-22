class ConceptNameTag < ActiveRecord::Base
  set_table_name :concept_name_tag
  set_primary_key :concept_name_tag_id
  include Openmrs
  named_scope :active, :conditions => ['concept_name_tag.voided = 0']
  has_many :concept_name_tag_map
  has_many :concept_name, :through => :concept_name_tag_map 
end

