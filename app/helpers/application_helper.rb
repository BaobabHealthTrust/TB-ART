# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def link_to_onmousedown(name, options = {}, html_options = nil, *parameters_for_method_reference)
    html_options = Hash.new if html_options.nil?
    html_options["onMouseDown"]="this.style.backgroundColor='lightblue';document.location=this.href"
    html_options["onClick"]="return false" #if we don't do this we get double clicks
    link = link_to(name, options, html_options, *parameters_for_method_reference)
  end

  def img_button_submit_to(url, image, options = {}, params = {})
    content = ""
    content << "<form method='post' action='#{url}'><input type='image' src='#{image}'/>"
    params.each {|n,v| content << "<input type='hidden' name='#{n}' value='#{v}'/>" }
    content << "</form>"
    content
  end
  
  def fancy_or_high_contrast_touch
    fancy = GlobalProperty.find_by_property("interface").property_value == "fancy" rescue false
    fancy ? "touch-fancy.css" : "touch.css"
  end
  
  def show_intro_text
    GlobalProperty.find_by_property("show_intro_text").property_value == "yes" rescue false
  end
  
  def ask_home_village
    GlobalProperty.find_by_property("demographics.home_village").property_value == "yes" rescue false
  end
  
  def ask_mothers_surname
    GlobalProperty.find_by_property("demographics.mothers_surname").property_value == "yes" rescue false
  end
  
  def ask_blood_pressure
    GlobalProperty.find_by_property("vitals.blood_pressure").property_value == "yes" rescue false
  end
  
  def ask_temperature
    GlobalProperty.find_by_property("vitals.temperature").property_value == "yes" rescue false
  end  

  def month_name_options
    i=0
    options_array = [[]] +Date::ABBR_MONTHNAMES[1..-1].collect{|month|[month,i+=1]} + [["Unknown","Unknown"]]
    options_for_select(options_array)  
  end
  
  def age_limit
    Time.now.year - 1890
  end

  def version
    "Mateme Version: #{MATEME_VERSION}#{' ' + MATEME_SETTINGS['installation'] if MATEME_SETTINGS}, #{File.ctime(File.join(RAILS_ROOT, 'config', 'environment.rb')).strftime('%d-%b-%Y')}"
  end
  
  def welcome_message
    "Muli bwanji, enter your user information or scan your id card. <span style='font-size:0.6em;float:right'>(#{version})</span>"  
  end
  
  def show_identifiers(location_id, patient)
    content = ""
    idents = GlobalProperty.find_by_property("dashboard.identifiers").property_value
    json = JSON.parse(idents)
    names = json[location_id.to_s] rescue []
    names.each do |name|
      ident_type = PatientIdentifierType.current.find_by_name(name)
      next if ident_type.blank?
      ident = patient.patient_identifiers.find_by_identifier_type(ident_type.id)
      next if ident.blank?
      content << "<span class='title'>#{name}:</span> #{ident.identifier}"       
    end
    content
  end
  
  def patient_image(patient) 
    @patient.person.gender == 'M' ? "<img src='/images/male.gif' alt='Male' height='30px' style='margin-bottom:-4px;'>" : "<img src='/images/female.gif' alt='Female' height='30px' style='margin-bottom:-4px;'>"
  end
end