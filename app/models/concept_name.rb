class ConceptName < ActiveRecord::Base
  set_table_name :concept_name
  set_primary_key :concept_name_id
  include Openmrs
  named_scope :active, :conditions => ['concept_name.voided = 0']
  named_scope :tagged, lambda{|tags| tags.blank? ? {} : {:include => :tags, :conditions => ['concept_name_tag.tag IN (?) AND concept_name_tag.voided = 0', Array(tags)]}}
  has_many :concept_name_tag_maps
  has_many :tags, :through => :concept_name_tag_maps, :class_name => 'ConceptNameTag'
  belongs_to :concept
end

