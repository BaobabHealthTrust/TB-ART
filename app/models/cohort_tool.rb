class CohortTool < ActiveRecord::Base
  set_table_name "encounter"

  def self.records_that_were_updated(quarter)

    date        = Report.generate_cohort_date_range(quarter)
    start_date  = (date.first.to_s  + " 00:00:00")
    end_date    = (date.last.to_s   + " 23:59:59")

    voided_records = {}

    other_encounters = Encounter.find_by_sql("SELECT encounter.* FROM encounter
                        INNER JOIN obs ON encounter.encounter_id = obs.encounter_id
                        WHERE ((encounter.encounter_datetime BETWEEN '#{start_date}' AND '#{end_date}'))
                        GROUP BY encounter.encounter_id
                        ORDER BY encounter.encounter_type, encounter.patient_id")

    drug_encounters = Encounter.find_by_sql("SELECT encounter.* as duration FROM encounter
                        INNER JOIN orders ON encounter.encounter_id = orders.encounter_id
                        WHERE ((encounter.encounter_datetime BETWEEN '#{start_date}' AND '#{end_date}'))
                        ORDER BY encounter.encounter_type")

    voided_encounters = []
    other_encounters.delete_if { |encounter| voided_encounters << encounter if (encounter.voided == 1)}

    voided_encounters.map do |encounter|
      patient           = Patient.find(encounter.patient_id)

      new_encounter  = other_encounters.reduce([])do |result, e|
        result << e if( e.encounter_datetime.strftime("%d-%m-%Y") == encounter.encounter_datetime.strftime("%d-%m-%Y")&&
                        e.patient_id      == encounter.patient_id &&
                        e.encounter_type  == encounter. encounter_type)
        result
      end

      new_encounter = new_encounter.last

      next if new_encounter.nil?

      voided_observations = encounter.voided_observations

      changed_to    = self.changed_to(new_encounter)
      changed_from  = self.changed_from(voided_observations)

      patient_arv_number = patient.get_identifier("ARV NUMBER")

      if( voided_observations && !voided_observations.empty?)
          voided_records[encounter.id] = {
              "id"              => patient.patient_id,
              "arv_number"      => patient_arv_number,
              "name"            => patient.name,
              "national_id"     => patient.national_id,
              "encounter_name"  => encounter.name,
              "voided_date"     => encounter.date_voided,
              "reason"          => encounter.void_reason,
              "change_from"     => changed_from,
              "change_to"       => changed_to
            }
      end
    end

    voided_treatments = []
    drug_encounters.delete_if { |encounter| voided_treatments << encounter if (encounter.voided == 1)}

    voided_treatments.each do |encounter|

      patient           = Patient.find(encounter.patient_id)

      orders            = encounter.orders
      changed_from      = ''
      changed_to        = ''

     new_encounter  =  drug_encounters.reduce([])do |result, e|
        result << e if( e.encounter_datetime.strftime("%d-%m-%Y") == encounter.encounter_datetime.strftime("%d-%m-%Y")&&
                        e.patient_id      == encounter.patient_id &&
                        e.encounter_type  == encounter. encounter_type)
          result
        end

      new_encounter = new_encounter.last

      next if new_encounter.nil?

      changed_from  += "Treatment: #{new_encounter.voided_orders.to_s.gsub!(":", " =>")}</br>"
      changed_to    += "Treatment: #{encounter.to_s.gsub!(":", " =>") }</br>"

      patient_arv_number = patient.get_identifier("ARV NUMBER")

      if( orders && !orders.empty?)
        voided_records[encounter.id]= {
            "id"              => patient.patient_id,
            "arv_number"      => patient_arv_number,
            "name"            => patient.name,
            "national_id"     => patient.national_id,
            "encounter_name"  => encounter.name,
            "voided_date"     => encounter.date_voided,
            "reason"          => encounter.void_reason,
            "change_from"     => changed_from,
            "change_to"       => changed_to
        }
      end

    end

    self.show_tabuler_format(voided_records)
  end

  def self.show_tabuler_format(records)

    patients = {}

    records.each do |key,value|

      sorted_values = self.sort(value)

      patients["#{key},#{value['id']}"] = sorted_values
    end

    patients
  end

  def self.sort(values)
    name              = ''
    patient_id        = ''
    arv_number        = ''
    national_id       = ''
    encounter_name    = ''
    voided_date       = ''
    reason            = ''
    obs_names         = ''
    changed_from_obs  = {}
    changed_to_obs    = {}
    changed_data      = {}

    values.each do |value|
      value_name =  value.first
      value_data =  value.last

      case value_name
        when "id"
          patient_id = value_data
        when "arv_number"
          arv_number = value_data
        when "name"
          name = value_data
        when "national_id"
          national_id = value_data
        when "encounter_name"
          encounter_name = value_data
        when "voided_date"
          voided_date = value_data
        when "reason"
          reason = value_data
        when "change_from"
          value_data.split("</br>").each do |obs|
            obs_name  = obs.split(':')[0].strip
            obs_value = obs.split(':')[1].strip rescue ''

            changed_from_obs[obs_name] = obs_value
          end unless value_data.blank?
        when "change_to"

          value_data.split("</br>").each do |obs|
            obs_name  = obs.split(':')[0].strip
            obs_value = obs.split(':')[1].strip rescue ''

            changed_to_obs[obs_name] = obs_value
          end unless value_data.blank?
      end
    end

    changed_from_obs.each do |a,b|
      changed_to_obs.each do |x,y|

        if (a == x)
          next if b == y
          changed_data[a] = "#{b} to #{y}"

          changed_from_obs.delete(a)
          changed_to_obs.delete(x)
        end
      end
    end

    changed_to_obs.each do |a,b|
      changed_from_obs.each do |x,y|
        if (a == x)
          next if b == y
          changed_data[a] = "#{b} to #{y}"

          changed_to_obs.delete(a)
          changed_from_obs.delete(x)
        end
      end
    end

    changed_data.each do |k,v|
      from  = v.split("to")[0].strip rescue ''
      to    = v.split("to")[1].strip rescue ''

      if obs_names.blank?
        obs_names = "#{k}||#{from}||#{to}||#{voided_date}||#{reason}"
      else
        obs_names += "</br>#{k}||#{from}||#{to}||#{voided_date}||#{reason}"
      end
    end

    results = {
        "id"              => patient_id,
        "arv_number"      => arv_number,
        "name"            => name,
        "national_id"     => national_id,
        "encounter_name"  => encounter_name,
        "voided_date"     => voided_date,
        "obs_name"        => obs_names,
        "reason"          => reason
      }

    results
  end

  def self.changed_from(observations)
    changed_obs = ''

    observations.collect do |obs|
      ["value_coded","value_datetime","value_modifier","value_numeric","value_text"].each do |value|
        case value
          when "value_coded"
            next if obs.value_coded.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_datetime"
            next if obs.value_datetime.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_numeric"
            next if obs.value_numeric.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_text"
            next if obs.value_text.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_modifier"
            next if obs.value_modifier.blank?
            changed_obs += "#{obs.to_s}</br>"
        end
      end
    end

    changed_obs.gsub("00:00:00 +0200","")[0..-6]
  end

  def self.changed_to(enc)
    encounter_type = enc.encounter_type

    encounter = Encounter.find(:first,
                 :joins       => "INNER JOIN obs ON encounter.encounter_id=obs.encounter_id",
                 :conditions  => ["encounter_type=? AND encounter.patient_id=? AND Date(encounter.encounter_datetime)=?",
                                  encounter_type,enc.patient_id, enc.encounter_datetime.to_date],
                 :group       => "encounter.encounter_type",
                 :order       => "encounter.encounter_datetime DESC")

    observations = encounter.observations rescue nil
    return if observations.blank?

    changed_obs = ''
    observations.collect do |obs|
      ["value_coded","value_datetime","value_modifier","value_numeric","value_text"].each do |value|
        case value
          when "value_coded"
            next if obs.value_coded.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_datetime"
            next if obs.value_datetime.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_numeric"
            next if obs.value_numeric.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_text"
            next if obs.value_text.blank?
            changed_obs += "#{obs.to_s}</br>"
          when "value_modifier"
            next if obs.value_modifier.blank?
            changed_obs += "#{obs.to_s}</br>"
        end
      end
    end

    changed_obs.gsub("00:00:00 +0200","")[0..-6]
  end

  def self.visits_by_day(quarter)
    date        = Report.generate_cohort_date_range(quarter)
    start_date  = (date.first.to_s + " 00:00:00")
    end_date    = (date.last.to_s + " 23:59:59")

    excluded_encounters = []
    excluded_encounters << EncounterType.find_by_name("Barcode scan").id rescue nil
    excluded_encounters << EncounterType.find_by_name("TB Reception").id rescue nil
    excluded_encounters << EncounterType.find_by_name("General Reception").id rescue nil
    excluded_encounters << EncounterType.find_by_name("Move file from dormant to active").id rescue nil
    excluded_encounters << EncounterType.find_by_name("Update outcome").id rescue nil

    visits_by_day = Hash.new(0)

    encounters = Encounter.find(:all,
                           :joins      => "INNER JOIN obs ON obs.encounter_id = encounter.encounter_id",
                           :conditions => ["obs.voided = 0 AND encounter_type NOT IN (?) AND encounter_datetime >=? AND encounter_datetime <=?", excluded_encounters,start_date,end_date],
                           :group      => "encounter.patient_id,DATE(encounter_datetime)",
                           :order      => "encounter.encounter_datetime ASC")

    encounters.map{|encounter|
      visits_by_day[encounter.encounter_datetime.strftime("%d-%b-%Y")] += 1
    }
    visits_by_day
  end

  def self.survival_analysis(survival_start_date=@start_date,
                        survival_end_date=@end_date,
                        outcome_end_date=@end_date, min_age=nil, max_age=nil)
    # Make sure these are always dates
    survival_start_date = start_date.to_date
    survival_end_date = end_date.to_date
    outcome_end_date = outcome_end_date.to_date

    date_ranges = Array.new
    first_registration_date = PatientRegistrationDate.find(:first,
      :order => 'registration_date').registration_date

    while (survival_start_date -= 1.year) >= first_registration_date
      survival_end_date   -= 1.year
      date_ranges << {:start_date => survival_start_date,
                      :end_date   => survival_end_date
      }
    end

    survival_analysis_outcomes = Array.new

    date_ranges.each_with_index do |date_range, i|
      outcomes_hash = Hash.new(0)
      all_outcomes = self.outcomes(date_range[:start_date], date_range[:end_date], outcome_end_date, min_age, max_age)

      outcomes_hash["Title"] = "#{(i+1)*12} month survival: outcomes by end of #{outcome_end_date.strftime('%B %Y')}"
      outcomes_hash["Start Date"] = date_range[:start_date]
      outcomes_hash["End Date"] = date_range[:end_date]

      survival_cohort = Reports::CohortByRegistrationDate.new(date_range[:start_date], date_range[:end_date])
      if max_age.nil?
        outcomes_hash["Total"] = survival_cohort.patients_started_on_arv_therapy.length rescue all_outcomes.values.sum
      else
        outcomes_hash["Total"] = all_outcomes.values.sum
      end
      outcomes_hash["Unknown"] = outcomes_hash["Total"] - all_outcomes.values.sum
      outcomes_hash["outcomes"] = all_outcomes

      # if there are no patients registered in that quarter, we must have
      # passed the real date when the clinic opened
      break if outcomes_hash["Total"] == 0
      
      survival_analysis_outcomes << outcomes_hash 
    end
    survival_analysis_outcomes
  end


  def self.cohort(period)
    date_range = Report.generate_cohort_date_range(period)
    start_date = date_range[0] ; end_date = date_range[1]
    cohort = Cohort.new()
  end

end
