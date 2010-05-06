class PatientProgram < ActiveRecord::Base
  set_table_name "patient_program"
  set_primary_key "patient_program_id"
  include Openmrs
  belongs_to :patient, :conditions => {:voided => 0}
  belongs_to :program, :conditions => {:retired => 0}
  belongs_to :location, :conditions => {:retired => 0}
  has_many :patient_states, :class_name => 'PatientState', :conditions => {:voided => 0}

  named_scope :current, :conditions => ['date_enrolled > ? AND (date_completed IS NULL OR date_completed > ?)', Time.now, Time.now]
  
  def after_void(reason = nil)
    self.patient_states.each{|row| row.void(reason) }
  end

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
  
  # This is a pretty clumsy way of finding which regimen the patient is on.
  # Eventually it would be good to have a way to associate a program with a
  # regimen type without doing it manually. Note, the location of the regimen
  # obs must be the current health center, not the station!
  def current_regimen
    location_id = Location.current_health_center.location_id
    obs = patient.person.observations.recent(1).all(:conditions => ['value_coded IN (?) AND location_id = ?', regimens, location_id])
    obs.first.value_coded rescue nil
  end

  def regimens(weight=nil)
    Regimen.program(program_id).criteria(weight).all(
      :select => 'concept_id', 
      :group => 'concept_id, program_id',
      :include => :concept).map(&:concept)
  end
      
end
