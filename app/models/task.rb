class Task < ActiveRecord::Base
  set_table_name :task
  set_primary_key :task_id
  include Openmrs

  named_scope :active, :conditions => ['task.voided = 0']

  # Try to find the next task for the patient at the given location
  def self.next_task(location, patient)
    all_tasks = self.active.all(:order => 'sort_weight ASC')
    todays_encounters = patient.encounters.current.all(:include => [:type])
    todays_encounter_types = todays_encounters.map{|e| e.type.name}
    all_tasks.each do |task|
      # Is the task for this location?
      next unless task.location.blank? || task.location == '*' || location.name.match(/#{task.location}/)
      # Have we already run this task?
      next if task.encounter_type.present? && todays_encounter_types.include?(task.encounter_type)
      # Are we checking gender and is it right?
      next if task.gender.present? && patient.person.gender != task.gender      
      # Check for an observation made today with a specific value
      if task.has_obs_concept_id.present?
        obs = Observation.first(:conditions => [
          'encounter_id IN (?) AND concept_id = ? AND (value_boolean = ? OR value_coded = ? OR value_drug = ? OR value_datetime = ? OR value_numeric = ? OR value_text = ?)',
          todays_encounter.map(&:encounter_id),
          task.has_obs_concept_id,
          task.has_obs_value_boolean,
          task.has_obs_value_coded,
          task.has_obs_value_drug,
          task.has_obs_value_datetime,
          task.has_obs_value_numberic,
          task.has_obs_value_text])
        next unless obs.present?  
      end
      # Check for a particular program state
      if task.has_program_id.present?
        patient_state = PatientState.active.current.first(:conditions => [
          'patient_id = ? AND program_id = ? AND state = ?',
          patient.patient_id,
          task.has_program_id,
          task.has_program_workflow_state_id])
        next unless patient_state.present?
      end
      # Nothing failed, this is the next task, lets replace any macros
      task.url = task.url.gsub(/\{patient\}/, "#{patient.patient_id}")
      task.url = task.url.gsub(/\{person\}/, "#{patient.person.person_id}")
      task.url = task.url.gsub(/\{location\}/, "#{location.location_id}")
      return task
    end
  end  
end
