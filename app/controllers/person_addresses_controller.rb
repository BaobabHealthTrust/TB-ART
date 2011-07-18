class PersonAddressesController < ApplicationController
  def village
    search("city_village", params[:search_string])
  end

  def traditional_authority
   # search("county_district", params[:search_string])
   search_location('ta', params[:search_string])
  end
  
  def landmark
    search("address1", params[:search_string])
  end

  def address2
    search("address2", params[:search_string])
  end

  def search(field_name, search_string)
    @names = PersonAddress.find_most_common(field_name, search_string).collect{|person_name| person_name.send(field_name)}
    render :text => "<li>" + @names.join("</li><li>") + "</li>"
    #redirect_to :action => :new, :address2 => params[:address2]
  end

  def current_residence
    search_location('residence', params[:search_string])
  end

  def home_village
    search_location('home_vge', params[:search_string])
  end
  
  def health_facility
    search_location('health_facility', params[:search_string])
  end
  
  def search_location(type, search_string)
    rsearch = search_string.gsub('r','l')
    lsearch = search_string.gsub('l','r')
  
    @results = []
    if type == 'residence'
      @areas = Location.areas.grep(/#{search_string}/i).compact.sort_by{|area| area.split(" ")[1].to_i}[0..60]
      @results = @areas + Location.current_residences.grep(/^#{search_string}|^#{rsearch}|^#{lsearch}/i).compact.sort_by{|location|
        location.index(/#{search_string}/) || 100 # if the search string isn't found use value 100
      }[0..10]
    elsif type == 'ta'
      @results = Location.tas.grep(/^#{search_string}|^#{rsearch}|^#{lsearch}/i).compact.sort_by{|ta|
          ta.index(/#{search_string}/) || 100 # if the search string isn't found use value 100
        }[0..10]
    elsif type == 'home_vge'
        @results = Location.current_residences.grep(/^#{search_string}|^#{rsearch}|^#{lsearch}/i).compact.sort_by{|location|
          location.index(/#{search_string}/) || 100 # if the search string isn't found use value 100
        }[0..10]
    elsif type == 'health_facility'
        @results = Location.health_facilities.grep(/^#{search_string}|^#{rsearch}|^#{lsearch}/i).compact.sort_by{|facility|
          facility.index(/#{search_string}/) || 100 # if the search string isn't found use value 100
        }[0..10]
    end


    render :text => @results.collect{|location|"<li>#{location}</li>"}.join("\n") + "<li>Other</li>"
  end
end
