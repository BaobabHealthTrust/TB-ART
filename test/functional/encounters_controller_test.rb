require File.dirname(__FILE__) + '/../test_helper'

class EncountersControllerTest < ActionController::TestCase
  fixtures :person, :person_name, :person_name_code, :person_address, 
           :patient, :patient_identifier, :patient_identifier_type,
           :concept, :concept_name, :concept_class,
           :encounter, :encounter_type, :obs

  def setup  
    @controller = EncountersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
  end

  context "Encounters controller" do
  
    context "Outpatient Diagnoses" do

      should "lookup diagnoses by name return them in the search results" do
        logged_in_as :mikmck, :registration do
          get :diagnoses, {:search_string => 'EXTRAPULMONARY'}
          assert_response :success
          assert_contains assigns(:suggested_answers), concept_name(:extrapulmonary_tuberculosis_without_lymphadenopathy).name
        end  
      end

      should "give patient drugs" do
        logged_in_as :mikmck, :registration do
          get :give_drugs, {:patient_id => patient(:evan).patient_id}
          assert_response :success
        end
      end

      should "process lab orders" do
        logged_in_as :mikmck, :registration do
          get :lab, {"encounter"=>{"patient_id"=>"1"},
                     "observations"=>[{"value_coded"=>"", "value_datetime"=>"",
                                       "order_id"=>"","obs_group_id"=>"","value_drug"=>"",
                                       "patient_id"=>"1", "value_coded_or_text_multiple"=>[""],
                                       "value_boolean"=>"","concept_name"=>"SELECT LAB ACTIVITY",
                                       "value_modifier"=>"","value_text"=>"",
                                       "obs_datetime"=>"2011-06-15T14:17:47+02:00",
                                       "value_numeric"=>"", "value_coded_or_text"=>"sputum_submission"}]}
          assert_response :redirect
       end
     end

     should "create a new encounter" do
      logged_in_as :mikmck, :registration do
       #TODO
       #get :new, {:patient_id => patient(:evan).patient_id, :encounter_type => "lab_order"}
       #assert_response :redirect
      end
     end

    end            
  end
end
