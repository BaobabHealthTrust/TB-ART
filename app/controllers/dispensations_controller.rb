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
      @order.drug_order.total_drug_supply(@patient, @encounter)
      redirect_to "/patients/treatment/#{@patient.patient_id}"
    else
      flash[:error] = "Could not dispense the drug for the prescription"
      redirect_to "/patients/treatment/#{@patient.patient_id}"
    end
  end  
  
  def quantities 
    drug = Drug.find(params[:formulation])
    # Most common quantity for the generic, not the specific
    concept_id = drug.concept_id
    # Grab the 10 most popular quantities for this drug
    amounts = []
    orders = DrugOrder.find(:all, 
      :select => 'quantity',
      :joins => 'LEFT JOIN orders ON orders.order_id = drug_order.order_id',
      :limit => 10, 
      :group => 'orders.concept_id, quantity', 
      :order => 'count(*)', 
      :conditions => ['orders.concept_id = ?', concept_id])
      
    orders.each {|order|
      amounts << "#{order.quantity.to_f}" unless order.quantity.blank?
    }  
    amounts = amounts.flatten.compact.uniq
    render :text => "<li>" + amounts.join("</li><li>") + "</li>"
  end
end
