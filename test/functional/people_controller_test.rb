require File.dirname(__FILE__) + '/../test_helper'

class PeopleControllerTest < ActionController::TestCase
  fixtures :person, :person_name, :person_name_code, :person_address,
           :person_attribute_type, :patient, :patient_identifier,
           :patient_identifier_type, :relationship_type, :person_attribute

  def setup  
    @controller = PeopleController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
  end

  context "People controller" do

    should "lookup people by name and gender and return them in the search results" do
      logged_in_as :mikmck, :registration do
        get :search, {:gender => 'M', :given_name => 'evan', :family_name => 'waters'}
        assert_response :success
        assert_contains assigns(:people), person(:evan)
      end  
    end

    should "lookup valid person by national id and redirect them to dashboard" do
      logged_in_as :mikmck, :registration do
        get :search, {:identifier => 'P1701210013'}
        assert_response :redirect
      end  
    end

    should "redirect to TB index search results page if params has to do with search of tb index info" do
      logged_in_as :mikmck, :registration do
        get :search, {:search_tb_index_person => patient(:evan).patient_id}
        assert_redirected_to("/people/new_tb_index_person")
      end
    end

    should "redirect to TB contact search results page if params has to do with search of tb contact info" do
      logged_in_as :mikmck, :registration do
        get :search, {:search_tb_contact_person => patient(:evan).patient_id}
        assert_redirected_to("/people/new_tb_contact_person")
      end
    end

    should "lookup people by national id that has no associated record and return them in the search results" do
      GlobalProperty.delete_all(:property => 'remote_demographics_servers')
      logged_in_as :mikmck, :registration do
        get :search, {:identifier => 'P16666666666'}
        assert_response :success
      end  
    end

    should "lookup people by national id that has no associated record and find the id from a remote"

    should "lookup demographics by posting a national id and return full demographic data" do
      logged_in_as :mikmck, :registration do
        get :demographics, {:person => {:patient => { :identifiers => {"National id" => "P1701210013" }}}}
        assert_response :success
      end  
    end

    should "lookup demographics by posting a national id that has no associated record and send them to the search page" do
      logged_in_as :mikmck, :registration do
        get :demographics, {:person => {:patient => { :identifiers => {"National id" => "P1666666666" }}}}
        assert_response :success
      end  
    end

    should "lookup people by posting a family name, first name and gender and return full demographic data" do
      logged_in_as :mikmck, :registration do
        get :demographics, {:person => {:gender => "M", :names => {:given_name => "Evan", :family_name => "Waters"}}}
        assert_response :success
      end  
    end

=begin
      # should "search for patients at remote sites and create them locally if they match **** UNDERCONSTRUCTION****" do
    should "search login at remote sites" do
      #logged_in_as :mikmck, :registration do
        post "http://localhost:3000/session/create?login=mikmck&password=mike&location=8"
        # get :demographics, {:person => {:patient => {:identifiers => "National id" => "P1701210013"}}}
        get "http://localhost:3000/people"
        assert_response :success
      #end  
    end

    should "search for patients at remote sites and create them locally if they match **** UNDERCONSTRUCTION****" do
      # tests search action given parameters from barcode scan, find by name or find by identifier whose details are on remote server
      logged_in_as :mikmck, :registration do
        #post "http://localhost:3000/session/create?login=mikmck&password=mike&location=8"
        get :demographics, {:person => {:patient => {:identifiers => { "National id" => "P1701210013"}}}}
        #get "http://localhost:3000/people"
        assert response.body =~ /aaaa/
      end
    end
=end
    should "lookup people that are not patients and return them in the search results" do
      logged_in_as :mikmck, :registration do      
        p = patient(:evan).destroy
        get :search, {:gender => 'M', :given_name => 'evan', :family_name => 'waters'}
        assert_response :success
        assert_contains assigns(:people), person(:evan)
      end  
    end

    should "not include voided people in the search results" do
      logged_in_as :mikmck, :registration do      
        p = person(:evan)
        p.void
        get :search, {:gender => 'M', :given_name => 'evan', :family_name => 'waters'}
        assert_response :success
        assert_does_not_contain assigns(:people), person(:evan)
      end  
    end

    should "create a new tb index person" do
      logged_in_as :mikmck, :registration do
        options = {"new_tb_index_person"=>{"relationship"=>["TB Contact Person","TB Index Person"],
                                           "gender"=>"M", "patient_id"=>patient(:evan).patient_id,
                                           "family_name"=>"Waters", "person_id"=>"0", "given_name"=>"Evan"}}

         assert_difference(Person, :count) { post :create_tb_index_person, options }
         assert_redirected_to("/encounters/new?patient_id=#{patient(:evan).patient_id}")# :redirect
      end
    end

    should "create a new tb contact person" do
      logged_in_as :mikmck, :registration do
        options =  {"new_tb_contact_person"=>{"relationship"=>["TB Patient", "TB contact Person"],
                               "gender"=>"M", "patient_id"=>"2", "family_name"=>"Baobab",
                               "person_id"=>"2", "given_name"=>"Health",
                               "birthday_params"=>{"age_estimate"=>"23","birth_month"=>"4",
                               "birth_day"=>"26", "birth_year"=>"1985"}}}
         assert_difference(Person, :count) { post :create_tb_contact_person, options }
         assert_redirected_to("/encounters/new?patient_id=2")
      end
    end

    should "not include voided names in the search results" do
      logged_in_as :mikmck, :registration do      
        name = person(:evan).names.first
        name.void
        get :search, {:gender => 'M', :given_name => 'evan', :family_name => 'waters'}
        assert_response :success
        assert_does_not_contain assigns(:people), person(:evan)
      end  
    end

    should "not include voided patients in the search results" do
      logged_in_as :mikmck, :registration do      
        evan = person(:evan)
        p = patient(:evan)
        p.void
        get :search, {:gender => 'M', :given_name => 'evan', :family_name => 'waters'}
        assert_response :success
        assert_does_not_contain assigns(:people), evan
      end  
    end

    should "select a person" do
      logged_in_as :mikmck, :registration do      
        get :select, {:person => person(:evan).person_id}
        assert_response :redirect
        get :select, {:person => 0, :given_name => 'Dennis', :family_name => 'Rodman', :gender => 'U'}
        assert_response :redirect
      end  
    end

    should "look up people for display on the default page" do
      logged_in_as :mikmck, :registration do      
        get :index
        assert_redirected_to("/clinic")
      end
    end

    should "set the date and time" do
      logged_in_as :mikmck, :registration do
        get :set_datetime, {"set_year"=>"2010", "set_month"=>"6", "set_day"=>"26"}
        assert_response :success
      end
    end

    should "reset the date and time" do
      logged_in_as :mikmck, :registration do
        get :reset_datetime
        assert_redirected_to("/")
      end
    end

    should "display the new person form" do
      logged_in_as :mikmck, :registration do      
        get :new
        assert_response :success
      end  
    end  

    should "create a person with their address and name records" do
      logged_in_as :mikmck, :registration do      
        options = {
          :person => {:birth_year => 1987, :birth_month => 2, :birth_day => 28,
            :gender => 'M', :cell_phone_number => 'Unknown', :occupation => 'Unknown',
            :landmark => "18A/745", :home_phone_number=>'Unknown', :office_phone_number=>'Unknown',
            :names => {:given_name => 'Bruce', :family_name => 'Wayne'},
            :addresses => {:county_district => 'Homeland', :city_village => 'Coolsville',
            :address1 => 'The Street' }
          }
        }
        assert_difference(Person, :count) { post :create, options }
        assert_difference(PersonAddress, :count) { post :create, options }
        assert_difference(PersonName, :count) { post :create, options }
        assert_response :redirect
      end  
    end

    should "allow for estimated birthdates" do
      logged_in_as :mikmck, :registration do      
        post :create, {
          :person => {          
            :birth_year => 'Unknown', 
            :age_estimate => 17,
            :gender => 'M',
            :cell_phone_number => 'Unknown',
            :occupation => 'Unknown',
            :landmark => "18A/745",
            :home_phone_number=>'Unknown',
            :office_phone_number=>'Unknown',
            :names => {:given_name => 'Bruce', :family_name => 'Wayne'},
            :addresses => {:county_district => 'Homeland', :city_village => 'Coolsville',
                           :address1 => 'The Street' }
          }
        }  
        assert_response :redirect
      end  
    end

    should "not create a patient unless specifically requested" do
      logged_in_as :mikmck, :registration do      
        options = {
        :person => {          
          :birth_year => 'Unknown', 
          :age_estimate => 17,
          :gender => 'M',
          :cell_phone_number => 'Unknown',
          :occupation => 'Unknown',
          :landmark => "18A/745",
          :home_phone_number=>'Unknown',
          :office_phone_number=>'Unknown',
          :names => {:given_name => 'Bruce', :family_name => 'Wayne'},
          :addresses => {:county_district => 'Homeland', :city_village => 'Coolsville',
          :address1 => 'The Street' }
          }  
        }
        assert_no_difference(Patient, :count) { post :create, options }
        options[:person].merge!(:patient => "")
        assert_difference(Patient, :count) { post :create, options }
      end
    end
  end
end
