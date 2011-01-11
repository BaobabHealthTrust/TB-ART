class PatientIdentifier < ActiveRecord::Base
  set_table_name "patient_identifier"
  set_primary_key :patient_identifier_id
  include Openmrs

  belongs_to :type, :class_name => "PatientIdentifierType", :foreign_key => :identifier_type, :conditions => {:retired => 0}
  belongs_to :patient, :class_name => "Patient", :foreign_key => :patient_id, :conditions => {:voided => 0}

  def self.calculate_checkdigit(number)
    # This is Luhn's algorithm for checksums
    # http://en.wikipedia.org/wiki/Luhn_algorithm
    # Same algorithm used by PIH (except they allow characters)
    number = number.to_s
    number = number.split(//).collect { |digit| digit.to_i }
    parity = number.length % 2

    sum = 0
    number.each_with_index do |digit,index|
      digit = digit * 2 if index%2==parity
      digit = digit - 9 if digit > 9
      sum = sum + digit
    end
    
    checkdigit = 0
    checkdigit = checkdigit +1 while ((sum+(checkdigit))%10)!=0
    return checkdigit
  end

  def self.next_available_arv_number
    current_arv_code = Location.current_arv_code
    type = PatientIdentifierType.find_by_name('ARV Number').id
    current_arv_number_identifiers = PatientIdentifier.find(:all,:conditions => ["identifier_type = ? AND voided = 0",type])
    assigned_arv_ids = current_arv_number_identifiers.collect{|identifier|
      $1.to_i if identifier.identifier.match(/#{current_arv_code} *(\d+)/)
    }.compact unless current_arv_number_identifiers.nil?
    next_available_number = nil
    if assigned_arv_ids.empty?
      next_available_number = 1
    else
      # Check for unused ARV idsV
      # Suggest the next arv_id based on unused ARV ids that are within 10 of the current_highest arv id. This makes sure that we don't get holes unless we   really want them and also means that our suggestions aren't broken by holes
      #array_of_unused_arv_ids = (1..highest_arv_id).to_a - assigned_arv_ids
      assigned_numbers = assigned_arv_ids.sort

      possible_number_range = GlobalProperty.find_by_property("arv_number_range").property_value.to_i rescue 100000
      possible_identifiers = Array.new(possible_number_range){|i|(i + 1)}
      next_available_number = ((possible_identifiers)-(assigned_numbers)).first
    end
    return "#{current_arv_code} #{next_available_number}"
  end
end
