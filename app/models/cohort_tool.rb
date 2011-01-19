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

end
