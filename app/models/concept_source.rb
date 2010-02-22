class ConceptSource < ActiveRecord::Base
  set_table_name :concept_source
  set_primary_key :concept_source_id
  include Openmrs
  named_scope :active, :conditions => ['concept_source.voided = 0']
  has_many :concept_maps, :class_name => 'ConceptMap', :foreign_key => :source
  has_many :concepts, :through => :concept_maps
end

