


class SurvivalAnalysis

  attr_accessor :start_date, :end_date


  def initialize(start_date, end_date)
    @start_date = "#{start_date} 00:00:00"
    @end_date = "#{end_date} 23:59:59"
  end


  def new_patients_registered_for_art

    PatientState.find_by_sql("SELECT * FROM (
                              SELECT s.patient_program_id, patient_id,patient_state_id,start_date,n.name,state FROM patient_state s
                              INNER JOIN patient_program p ON p.patient_program_id = s.patient_program_id
                              INNER JOIN program_workflow_state w ON w.program_workflow_id = p.program_id AND w.program_workflow_state_id = s.state
                              INNER JOIN concept_name n ON w.concept_id = n.concept_id
                              WHERE p.voided = 0 AND s.voided = 0
                              AND (p.date_enrolled >= '2011-01-01' AND p.date_enrolled <= '2011-03-31')
                              AND p.program_id = 1
                              ORDER BY 
                              patient_id DESC, patient_state_id DESC , start_date DESC) K
                              GROUP BY K.patient_program_id
                              ORDER BY K.patient_state_id DESC , K.start_date DESC")
    
  end


end
