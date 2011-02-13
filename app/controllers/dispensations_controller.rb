class DispensationsController < ApplicationController
  def new
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    @prescriptions = @patient.orders.current.prescriptions.all
    @options = @prescriptions.map{|presc| [presc.drug_order.drug.name, presc.drug_order.drug_inventory_id]}
  end
  
  def create
    if (params[:identifier])
      params[:drug_id] = params[:identifier].match(/^\d+/).to_s
      params[:quantity] = params[:identifier].match(/\d+$/).to_s
    end
    @patient = Patient.find(params[:patient_id] || session[:patient_id]) rescue nil
    @encounter = @patient.current_dispensation_encounter
    @drug = Drug.find(params[:drug_id])
    @order = @patient.current_treatment_encounter.orders.current.prescriptions.first(:conditions => ['drug_order.drug_inventory_id = ?', params[:drug_id]])
    # Do we have an order for the specified drug?
    if @order.blank?
      flash[:error] = "There is no prescription for #{@drug.name}"
      redirect_to "/patients/treatment/#{@patient.patient_id}" and return
    end
    # Try to dispense the drug    
    obs = Observation.new(
      :concept_name => "AMOUNT DISPENSED",
      :order_id => @order.order_id,
      :person_id => @patient.person.person_id,
      :encounter_id => @encounter.id,
      :value_drug => @order.drug_order.drug_inventory_id,
      :value_numeric => params[:quantity],
      :obs_datetime => Time.now)
    if obs.save
      @patient.patient_programs.find_by_program_id(Program.find_by_name("HIV PROGRAM")).transition(:state => "ON ANTIRETROVIRALS") if @drug.arv? rescue nil
      @order.drug_order.total_drug_supply(@patient, @encounter)
      @patient.set_received_regimen(@encounter,@order) if @order.drug_order.drug.arv?
      Pharmacy.dispensed_stock_adjustment(@patient.current_treatment_encounter)
      redirect_to "/patients/treatment/#{@patient.patient_id}"
    else
      flash[:error] = "Could not dispense the drug for the prescription"
      redirect_to "/patients/treatment/#{@patient.patient_id}"
    end
  end  
  
  def quantities 
    drug = Drug.find(params[:formulation])
    # Most common quantity should be for the generic, not the specific
    # But for now, the value_drug shortcut is significant enough that we 
    # Should just use it. Also, we are using the AMOUNT DISPENSED obs
    # and not the drug_order.quantity because the quantity contains number
    # of pills brought to clinic and we should assume that the AMOUNT DISPENSED
    # observations more accurately represent pack sizes
    amounts = []
    Observation.question("AMOUNT DISPENSED").all(
      :conditions => {:value_drug => drug.drug_id},
      :group => 'value_drug, value_numeric',
      :order => 'count(*)',
      :limit => '10').each do |obs|
      amounts << "#{obs.value_numeric.to_f}" unless obs.value_numeric.blank?
    end
    amounts = amounts.flatten.compact.uniq
    render :text => "<li>" + amounts.join("</li><li>") + "</li>"
  end
end
