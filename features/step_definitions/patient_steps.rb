Given /^the patient is "([^\"]*)"$/ do |name|
  case name
    when "Child"
      @person = Factory.create(:person, :birthdate => Date.parse('2005-01-01'), :birthdate_estimated => 0, :gender => 'M')
      @patient = Factory.create(:patient, :person => @person, :patient_id => @person.person_id)
      @patient.person.names << Factory.create(:person_name)
      assert_not_nil @patient.person
      assert_not_nil @patient.person.age
    when "Woman"
      @person = Factory.create(:person, :birthdate => Date.parse('1992-01-01'), :birthdate_estimated => 0, :gender => 'F')
      @patient = Factory.create(:patient, :person => @person, :patient_id => @person.person_id)
      @patient.person.names << Factory.create(:person_name)
      assert_not_nil @patient.person
      assert_not_nil @patient.person.age
  end
end

Then /^the patient should have an? "([^\"]*)" encounter$/ do |name|
  todays_encounters = @patient.encounters.current.all(:include => [:type])
  todays_encounter_types = todays_encounters.map{|e| e.type.name rescue ''}
  todays_encounter_types += todays_encounters.map{|e| e.type.name.gsub(/.*\//,"").gsub(/\..*/,"").humanize rescue ''}
  assert todays_encounter_types.include?(name)
end