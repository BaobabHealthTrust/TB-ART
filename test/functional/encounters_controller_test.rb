require File.dirname(__FILE__) + '/../test_helper'

class EncountersControllerTest < ActionController::TestCase
  fixtures :person, :person_name, :person_name_code, :person_address, 
           :patient, :patient_identifier, :patient_identifier_type,
           :concept, :concept_name, :concept_class, :concept_set,
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

      should "get lab activity" do
        logged_in_as :mikmck, :registration do
          get :lab, {"encounter"=>{"patient_id"=>"1"},
                     "observations"=>[{"patient_id"=>"1",
                                       "concept_name"=>"SELECT LAB ACTIVITY",
                                       "value_coded_or_text"=>"sputum_submission"}]}
          assert_response :redirect
       end
     end
  
     should "process patient lab orders" do
       logged_in_as :mikmck, :registration do
         get :lab_orders, {:patient_id => patient(:evan).patient_id,
                           :encounter_type=>encounter_type(:lab_orders), :sample => 'Sputum'}
         assert_response :success
        end
      end

     should "create a new encounter" do
      logged_in_as :mikmck, :registration do
       get :create, {:encounter => { :provider_id => "1",
                                     :encounter_type_name => "LAB ORDERS",
                                     :patient_id => patient(:evan).patient_id,
                                     :encounter_datetime=>"2011-06-27T12:36:44+02:00"},
                     :main_tests => "Blood",
                     :observations => [{ :patient_id => patient(:evan).patient_id,
                                        :concept_name => "TESTS ORDERED",
                                        :value_coded_or_text_multiple => ["CD4 count"],
                                        :obs_datetime => "2011-06-27T12:36:44+02:00"}]}        
       assert_response :redirect
      end
     end
 
    end            
  end
end
