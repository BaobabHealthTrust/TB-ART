def require_patient
  raise "You need to select a patient before you can use this task" unless @patient
end

When /^I start the task "([^\"]*)"$/ do |task|
  require_patient

  case task
    when "Art Clinician Visit":
      visit '/encounters/new/art_clinician_visit?patient_id='+@patient.patient_id
  end
end