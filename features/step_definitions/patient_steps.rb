Given /^the patient is "([^\"]*)"$/ do |name|
  case name
    when "Child"
      @person = Factory.create(:person, :birthdate => Date.parse('2005-01-01'), :birthdate_estimated => 0)
      @patient = Factory.create(:patient, :person => @person, :patient_id => @person.person_id)
      @patient.person.names << Factory.create(:person_name)
      assert_not_nil @patient.person
      assert_not_nil @patient.person.age
  end
end