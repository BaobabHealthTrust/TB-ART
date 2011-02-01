class Cohort

  attr_accessor :total_registered, :patients_initiated_on_art_first_time,:patients_reinitiated_on_art,:patients_transfered_out
  attr_accessor :all_males,:non_pregnant_women,:pregnant_women
  attr_accessor :infants_at_initiation,:children_at_initiation,:adults_at_initiation,:unknown_age_at_initiation
  attr_accessor :presumed_severe_hiv_disease_in_infants,:confirmed_hiv_infection_in_infants,:who_stage_1_or_2_cd4,
    :who_stage_2_lymphocyte,:who_stage_3,:who_stage_4,:other_reasons
  attr_accessor :no_tb,:tb_within_the_last_2_yrs,:current_espisode_of_tb,:kaposis_sarcoma
  attr_accessor :total_alive_and_on_art,:died_within_1st_month,:died_within_2nd_month,:died_within_3rd_month,:died_after_3rd_month,:died_total,
    :defaulters,:stopped,:transferred_out_patients,:unknown_outcome
  attr_accessor :d4T_3TC_NVP,:AZT_3TC_NVP,:d4T_3TC_EFV,:AZT_3TC_EFV,:AZT_3TC_TDF_LPVr,:ddl_ABC_LPVr,:non_standard
  attr_accessor :total_patients_side_effects,:tb_not_suspected_patients,:tb_suspected_patients,:tb_confirmed_not_on_treatment_patients,
    :tb_confirmed_on_treatment_patients,:tb_status_unknown_patients
  attr_accessor :patients_with_pill_count_less_than_seven,:patients_with_pill_count_more_than_seven

  attr_accessor :start_date, :end_date

  # Initialize class
  def initialize(start_date, end_date)
    @start_date = "#{start_date} 00:00:00"
    @end_date = "#{end_date} 23:59:59"
  end

  # Get patients reinitiated on art count
  def patients_reinitiated_on_art_ever
    Observation.find(:all, :joins => [:encounter], :conditions => ["concept_id = ? AND value_coded IN (?) AND encounter.voided = 0 \
        AND DATE_FORMAT(obs_datetime, '%Y-%m-%d') <= ?", ConceptName.find_by_name("EVER RECEIVED ART?").concept_id,
        ConceptName.find(:all, :conditions => ["name = 'YES'"]).collect{|c| c.concept_id},
        @end_date.to_date.strftime("%Y-%m-%d")]).length rescue 0
  end

  def patients_reinitiated_on_art
    Observation.find(:all, :joins => [:encounter], :conditions => ["concept_id = ? AND value_coded IN (?) AND encounter.voided = 0 \
        AND DATE_FORMAT(obs_datetime, '%Y-%m-%d') >= ? AND DATE_FORMAT(obs_datetime, '%Y-%m-%d') <= ?",
        ConceptName.find_by_name("EVER RECEIVED ART?").concept_id,
        ConceptName.find(:all, :conditions => ["name = 'YES'"]).collect{|c| c.concept_id},
        @start_date.to_date.strftime("%Y-%m-%d"), @end_date.to_date.strftime("%Y-%m-%d")]).length rescue 0
  end

  def outcomes(start_date=@start_date, end_date=@end_date, outcome_end_date=@end_date, program_id = nil, min_age=nil, max_age=nil,states = [])

    if min_age or max_age
      conditions = "AND TRUNCATE(DATEDIFF(p.date_enrolled, person.birthdate)/365,0) >= #{min_age}
                    AND TRUNCATE(DATEDIFF(p.date_enrolled, person.birthdate)/365,0) <= #{max_age}"
    end

    PatientState.find_by_sql("SELECT * FROM (
                              SELECT s.patient_program_id, patient_id,patient_state_id,start_date,n.name name,state
                              FROM patient_state s
                              INNER JOIN patient_program p ON p.patient_program_id = s.patient_program_id
                              INNER JOIN program_workflow_state w ON w.program_workflow_id = p.program_id AND w.program_workflow_state_id = s.state
                              INNER JOIN concept_name n ON w.concept_id = n.concept_id
                              INNER JOIN person ON person.person_id = p.patient_id
                              WHERE p.voided = 0 AND s.voided = 0 #{conditions}
                              AND (p.date_enrolled >= '#{start_date}' AND p.date_enrolled <= '#{end_date}')
                              AND p.program_id = #{program_id} AND s.start_date <= '#{outcome_end_date}'
                              ORDER BY 
                              patient_id DESC, patient_state_id DESC , start_date DESC) K
                              GROUP BY K.patient_program_id
                              ORDER BY K.patient_state_id DESC , K.start_date DESC").map{| state | states << [state.patient_id , state.name] }
  end

end
