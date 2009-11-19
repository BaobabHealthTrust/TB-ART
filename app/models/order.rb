class Order < ActiveRecord::Base
  include Openmrs
  set_table_name :orders
  set_primary_key :order_id
  belongs_to :order_type
  belongs_to :concept
  belongs_to :encounter
  belongs_to :patient
  belongs_to :provider, :foreign_key => 'orderer', :class_name => 'User'
  belongs_to :observation, :foreign_key => 'obs_id', :class_name => 'Observation'
  has_one :drug_order
  named_scope :active, :conditions => ['voided = 0 AND discontinued = 0']
  
  def to_s
    "#{drug_order}"
  end
end

