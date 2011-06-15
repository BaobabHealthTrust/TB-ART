class PeopleController < ApplicationController
  def index
    redirect_to "/clinic"
  end
 
  def new
    @occupations = Person.occupations
  end
  
  def identifiers
  end

  def demographics
    # Search by the demographics that were passed in and then return demographics
    people = Person.find_by_demographics(params)
    result = people.empty? ? {} : people.first.demographics
    render :text => result.to_json
  end

  def search
    #redirect to TB index search results page if params has to do with search of tb index info   
    if params[:search_tb_index_person]
      redirect_to :action => :new_tb_index_person, :gender => params[:gender],:given_name => params[:given_name],
                             :family_name => params[:family_name], :patient_id => params[:patient_id],
                             :source_of_referral => params[:source_of_referral] and return
    end

    #redirect to TB contact search results page if params has to do with search of tb contact info
    if params[:search_tb_contact_person]

      redirect_to :action => :new_tb_contact_person, :gender => params[:gender],
                             :given_name => params[:given_name],
                             :family_name => params[:family_name], :person_id => params[:person],
                             :patient_id => params[:patient_id],
                             :number_of_contacts => params[:number_of_contacts],
                             :tb_contact_birth_year => params[:tb_contact_birth_year],
                             :tb_contact_birth_month => params[:tb_contact_birth_month],
                             :tb_contact_age_estimate => params[:tb_contact_age_estimate],
                             :tb_contact_birth_day => params[:tb_contact_birth_day],
                             :source => params[:source] and return
    end

    found_person = nil
    if params[:identifier]
      local_results = Person.search_by_identifier(params[:identifier])
      if local_results.length > 1
        @people = Person.search(params)
      elsif local_results.length == 1
        found_person = local_results.first
      else
        # TODO - figure out how to write a test for this
        # This is sloppy - creating something as the result of a GET
        found_person_data = Person.find_remote_by_identifier(params[:identifier])
        found_person =  Person.create_from_form(found_person_data) unless found_person_data.nil?
      end
      if found_person
        #raise "--#{found_person.id}---#{params[:relation]}--".to_yaml
        redirect_to search_complete_url(found_person.id, params[:relation]) and return
      end
    end

    @people = Person.search(params)
  end
 
  # This method is just to allow the select box to submit, we could probably do this better
  def select
     
    if params[:source_of_referral]
       referral_source = PersonAttribute.create({:person_id => params[:patient_id],
                            :value => params[:source_of_referral],
                            :person_attribute_type_id => PersonAttributeType.find(:first, :conditions => ["name = ?","Source of referral"]).id})
       referral_source.save

       redirect_to :action => :create_tb_index_person, :new_tb_index_person => {:gender => params[:gender],
                   :given_name => params[:given_name], :family_name => params[:family_name],
                   :person_id => params[:person], :patient_id => params[:patient_id],
                   :relationship => ["TB Contact Person", "TB Index Person"]} and return
     end

    if params[:number_of_contacts]
       number_of_contacts = PersonAttribute.create({:person_id => params[:patient_id],
                               :value => params[:number_of_contacts],
                               :person_attribute_type_id => PersonAttributeType.find(:first, :conditions => ["name = ?","Number of TB contacts"]).id})
       number_of_contacts.save

       redirect_to :action => :create_tb_contact_person, :source => params[:source],
                              :new_tb_contact_person => {
                                 :gender => params[:gender], :given_name => params[:given_name],
                                 :family_name => params[:family_name],:person_id => params[:person],
                                 :patient_id => params[:patient_id],
                                 :birthday_params => {
                                     :birth_year => params[:tb_contact_birth_year],
                                     :birth_month => params[:tb_contact_birth_month],
                                     :age_estimate => params[:tb_contact_age_estimate],
                                     :birth_day => params[:tb_contact_birth_day]},
                                 :relationship => ["TB Patient","TB contact Person"]} and return
    end

    redirect_to search_complete_url(params[:person], params[:relation]) and return unless params[:person].blank? || params[:person] == '0'
    redirect_to :action => :new, :gender => params[:gender], :given_name => params[:given_name], :family_name => params[:family_name],
    :family_name2 => params[:family_name2], :address2 => params[:address2], :identifier => params[:identifier], :relation => params[:relation]
  end
 
  def create
    person = Person.create_from_form(params[:person])
    if params[:person][:patient]
      person.patient.national_id_label
      unless (params[:relation].blank?)
        print_and_redirect("/patients/national_id_label/?patient_id=#{person.patient.id}", search_complete_url(person.id, params[:relation]))      
      else
        print_and_redirect("/patients/national_id_label/?patient_id=#{person.patient.id}", next_task(person.patient))
      end
    else
      # Does this ever get hit?
      redirect_to :action => "index"
    end
  end

  # TODO refactor so this is restful and in the right controller.
  def set_datetime
    if request.post?
      unless params["retrospective_patient_day"]== "" or params["retrospective_patient_month"]== "" or params["retrospective_patient_year"]== ""
        # set for 1 second after midnight to designate it as a retrospective date
        date_of_encounter = Time.mktime(params["retrospective_patient_year"].to_i,
                                        params["retrospective_patient_month"].to_i,
                                        params["retrospective_patient_day"].to_i,0,0,1)
        session[:datetime] = date_of_encounter if date_of_encounter.to_date != Date.today
      end
      redirect_to :action => "index"
    end
  end

  def reset_datetime
    session[:datetime] = nil
    redirect_to :action => "index" and return
  end

  def new_tb_index_person
    @patient = Patient.find(params[:patient_id] || session[:patient_id])
    @people = Person.search(params)
  end

  def create_tb_index_person
    Person.create_tb_index_or_contact(params[:new_tb_index_person])
    redirect_to search_complete_url(params[:new_tb_index_person][:patient_id], '')
  end

  def new_tb_contact_person
    @patient = Patient.find(params[:patient_id] || session[:patient_id])
    @people = Person.search(params)
  end

  def create_tb_contact_person
    Person.create_tb_index_or_contact(params[:new_tb_contact_person])

    if params[:source] == "create_ipt"
      redirect_to("/encounters/new/ipt_contact_person?patient_id=#{params[:new_tb_contact_person][:patient_id]}")
    else
      redirect_to search_complete_url(params[:new_tb_contact_person][:patient_id], '')
    end
  end

private

  def search_complete_url(found_person_id, primary_person_id)
    unless (primary_person_id.blank?)
      # Notice this swaps them!
      #raise "A--#{found_person_id}---#{primary_person_id}--".to_yaml
      new_relationship_url(:patient_id => primary_person_id, :relation => found_person_id)
    else
      #raise "B--#{found_person_id}---#{primary_person_id}--".to_yaml
      url_for(:controller => :encounters, :action => :new, :patient_id => found_person_id)
    end
  end
end
