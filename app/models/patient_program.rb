class PatientProgram < ActiveRecord::Base
  set_table_name "patient_program"
  set_primary_key "patient_program_id"
  include Openmrs
  belongs_to :patient
  belongs_to :program
  belongs_to :location
  has_many :patient_states, :class_name => 'PatientState'

  named_scope :active, :conditions => ['patient_program.voided = 0 AND program.retired = 0'], :include => :program
  named_scope :current, :conditions => ['date_enrolled > ? AND (date_completed IS NULL OR date_completed > ?)', Time.now, Time.now]
  
  def to_s
    self.program.concept.name.name + " (at #{location.name})"
  end
  
  def transition(params)
    ActiveRecord::Base.transaction do
      # Check if there is an open state and close it
      state = self.patient_states.last
      if (state && state.end_date.blank?)
        state.end_date = params[:start_date]
        state.save!
      end    
      # Create the new state
      state = self.patient_states.new(params)
      state.save!
    end  
  end
  
  def complete(end_date)
    self.date_completed = end_date
    self.save!
  end
end
