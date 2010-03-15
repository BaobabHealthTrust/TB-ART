class Task < ActiveRecord::Base
  set_table_name :task
  set_primary_key :task_id
  include Openmrs

  # Try to find the next task for the patient at the given location
  def self.next_task(location, patient)
    all_tasks = self.all(:order => 'sort_weight ASC')
    todays_encounters = patient.encounters.current.all(:include => [:type])
    todays_encounter_types = todays_encounters.map{|e| e.type.name rescue ''}
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
          'encounter_id IN (?) AND concept_id = ? AND (value_coded = ? OR value_drug = ? OR value_datetime = ? OR value_numeric = ? OR value_text = ?)',
          todays_encounters.map(&:encounter_id),
          task.has_obs_concept_id,
          task.has_obs_value_coded,
          task.has_obs_value_drug,
          task.has_obs_value_datetime,
          task.has_obs_value_numeric,
          task.has_obs_value_text])
        next unless obs.present?  
      end

      # Check for a particular current order type
      if task.has_order_type_id.present?
        next unless Order.unfinished.first(
          :conditions => {:order_type_id => task.has_order_type_id})
      end

      # Check for a particular program state at this location      
      if task.has_program_id.present?
        patient_state = PatientState.current.first(:conditions => [
          'patient_program.patient_id = ? AND patient_program.location_id = ? AND patient_program.program_id = ? AND patient_state.state = ?',
          patient.patient_id,
          Location.current_health_center.location_id,
          task.has_program_id,
          task.has_program_workflow_state_id],
          :include => :patient_program)
        next unless patient_state.present?
      end
      
      # Check for a particular relationship
      if task.has_relationship_type_id.present?        
        next unless patient.relationships.first(
          :conditions => ['relationship.relationship = ?', task.has_relationship_type_id])
      end

      # Check for a particular identifier at this location
      if task.has_identifier_type_id.present?
        next unless patient.patient_identifiers.first(
          :conditions => ['patient_identifier.identifier_type = ? AND patient_identifier.location_id = ?', task.has_identifier_type_id, Location.current_health_center.location_id])
      end

      # Nothing failed, this is the next task, lets replace any macros
      task.url = task.url.gsub(/\{patient\}/, "#{patient.patient_id}")
      task.url = task.url.gsub(/\{person\}/, "#{patient.person.person_id rescue nil}")
      task.url = task.url.gsub(/\{location\}/, "#{location.location_id}")
      return task
    end
  end  
end
