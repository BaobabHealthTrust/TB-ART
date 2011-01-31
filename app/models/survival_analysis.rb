


class SurvivalAnalysis

  attr_accessor :start_date, :end_date


  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end


  def survival_analysis

    outcomes = {} ; months = 12 ; patients_found = true ; survival_end_date = self.end_date ; survival_start_date = self.start_date
    clinic_start_date = PatientProgram.find(:first,:conditions =>["program_id = ? AND voided = 0",1],
                                            :order => 'date_enrolled ASC').date_enrolled.to_date rescue nil
    return if clinic_start_date.blank?
    return if self.end_date < clinic_start_date
    date_ranges = []

    while survival_end_date >= clinic_start_date
      date_ranges << {:start_date => survival_start_date -= 1.year}
      survival_end_date -= 1.year
    end

    states = [] ; i = 1

    (date_ranges || [] ).each do | range |
      states = []
      PatientState.find_by_sql("SELECT * FROM (
                              SELECT s.patient_program_id, patient_id,patient_state_id,start_date,n.name name,state FROM patient_state s
                              INNER JOIN patient_program p ON p.patient_program_id = s.patient_program_id
                              INNER JOIN program_workflow_state w ON w.program_workflow_id = p.program_id AND w.program_workflow_state_id = s.state
                              INNER JOIN concept_name n ON w.concept_id = n.concept_id
                              WHERE p.voided = 0 AND s.voided = 0
                              AND (p.date_enrolled >= #{range[:start_date]} AND p.date_enrolled <= '#{self.end_date}')
                              AND p.program_id = 1
                              ORDER BY 
                              patient_id DESC, patient_state_id DESC , start_date DESC) K
                              GROUP BY K.patient_program_id
                              ORDER BY K.patient_state_id DESC , K.start_date DESC").map{| state | states << state.name }
    
      outcomes["#{(i)*12} month survival: outcomes by end of #{self.end_date.strftime('%B %Y')}"] = {'Number Alive and on ART' => 0,'Number Dead' => 0,
      'Number Defaulted' => 0 ,'Number Stopped Treatment' => 0, 'Number Transferred out' => 0, 'Unknown' => 0,'New patients registered for ART' => states.length}
      (states || [] ).each do | state |
        case state
          when 'PATIENT TRANSFERRED OUT'
             outcomes["#{(i)*12} month survival: outcomes by end of #{self.end_date.strftime('%B %Y')}"]['Number Transferred out']+=1 
          when 'PATIENT DIED'
             outcomes["#{(i)*12} month survival: outcomes by end of #{self.end_date.strftime('%B %Y')}"]['Number Dead']+=1 
          when 'TREATMENT STOPPED'
             outcomes["#{(i)*12} month survival: outcomes by end of #{self.end_date.strftime('%B %Y')}"]['Number Stopped Treatment']+=1 
          when 'ON ANTIRETROVIRALS'
             outcomes["#{(i)*12} month survival: outcomes by end of #{self.end_date.strftime('%B %Y')}"]['Number Alive and on ART']+=1 
        end
      end
      i+=1
    end
    return outcomes
  end


end
