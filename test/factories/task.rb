Factory.define :task, :class => :task do |task|
  task.url "/people/new_tb_index_person?patient_id={patient}"
  task.encounter_type "REGISTRATION"
  task.description "Registration clerk needs to do registration if it hasn't happened yet"
  task.location "Registration"
  task.sort_weight 1
end
