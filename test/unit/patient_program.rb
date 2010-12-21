require File.dirname(__FILE__) + '/../test_helper'

class PatientProgramTest < ActiveSupport::TestCase
  fixtures :patient, :patient_identifier, :person_name, :person, :encounter, :encounter_type, :concept, :concept_name, :obs

  context "Patient Programs" do
    should "be valid" do
      patient_program = Factory(:patient_program)
      patient_program.program = Factory(:program)
      assert patient_program.valid?
    end

    should "not allow overlap for same program" do
      program = Factory(:program)
      patient_program1 = Factory(:patient_program)
      patient_program1.program = program
      patient_program1.save
      patient_program2 = Factory(:patient_program)
      patient_program2.program = program
      assert !patient_program2.valid?
      puts patient_program2.errors.full_messages
    end

    should "allow overlap for same program different date ranges" do
      program = Factory(:program)
      patient_program1 = Factory(:patient_program)
      patient_program1.program = program
      patient_program1.date_enrolled = Time.now - 1.year
      patient_program1.date_completed = Time.now - 6.months
      patient_program1.save
      patient_program2 = Factory(:patient_program)
      patient_program2.program = program
      assert patient_program2.valid?
    end

    should "allow overlap of different program" do
      program1 = Factory(:program)
      program2 = Factory(:program)
      patient_program1 = Factory(:patient_program)
      patient_program1.program = program1
      patient_program1.save
      patient_program2 = Factory(:patient_program)
      patient_program2.program = program2
      assert patient_program2.valid?
    end

  end
end
