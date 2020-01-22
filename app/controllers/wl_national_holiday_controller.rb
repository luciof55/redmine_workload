class WlNationalHolidayController < ApplicationController
  unloadable
  require 'json'
 
  before_action :check_edit_rights, only: [:edit, :update, :create, :destroy]
  before_action :select_year 
  before_action :load_places, :load_half_day_options, only: [:index, :new, :edit, :update, :create]
  
  helper :work_load
  
  def index            
    filter_year_start=Date.new(@this_year,01,01)
    filter_year_end=Date.new(@this_year,12,31)
    @wl_national_holiday = WlNationalHoliday.where("start_holliday between ? AND ?", filter_year_start, filter_year_end)
    @is_allowed = User.current.allowed_to_globally?(:edit_national_holiday)
  end
  
  def new
	@wl_national_holiday = WlNationalHoliday.new()
	@wl_national_holiday.start_holliday = Date.today
  end
  
  def edit
    @wl_national_holiday = WlNationalHoliday.find(params[:id]) rescue nil 
  end    
  
  def update
    national_holiday = WlNationalHoliday.find(params[:id]) rescue nil
	
	national_holiday.start_holliday = params[:wl_national_holiday][:start_holliday]
	national_holiday.reason = params[:wl_national_holiday][:reason]
	national_holiday.half_day = params[:wl_national_holiday][:half_day]
	national_holiday.place = params[:wl_national_holiday][:place]
	national_holiday.end_holliday = national_holiday.start_holliday
    
	respond_to do |format|
		if national_holiday.save
			format.html { redirect_to(:action => 'index', :notice => 'Holiday was successfully updated.', :params => { :year =>params[:year]} ) }
			format.xml  { head :ok }
		else
			format.html { 
			  flash[:error] = "<ul>" + national_holiday.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>"
			  redirect_to(:action => 'edit') }
			format.xml  { render :xml => national_holiday.errors, :status => :unprocessable_entity }
		end
    end
  end
  
  def create
    national_holiday = WlNationalHoliday.new
		
	national_holiday.start_holliday = params[:wl_national_holiday][:start_holliday]
	national_holiday.reason = params[:wl_national_holiday][:reason]
	national_holiday.half_day = params[:wl_national_holiday][:half_day]
	national_holiday.place = params[:wl_national_holiday][:place]
	national_holiday.end_holliday = national_holiday.start_holliday
	
    if national_holiday.save
      redirect_to action: 'index', notice: 'Holiday was successfully saved.', year: params[:year]
    else
      respond_to do |format| 
        format.html {
          flash[:error] = "<ul>" + national_holiday.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>" 
          redirect_to(:action => 'new') }
        format.api  { render_validation_errors(national_holiday) }
      end 
    end    
  end
  
  def destroy
    @wl_national_holiday = WlNationalHoliday.find(params[:id]) rescue nil
    @wl_national_holiday.destroy
    
    redirect_to(:action => 'index', :notice => 'Holiday was successfully deleted.', :year => params[:year])
  end


private

	def load_places
		@items = []
		custom_field = CustomField.where("name = 'Sede'").first
		if custom_field
			Rails.logger.info("custom_field: " + custom_field.to_s)
			Rails.logger.info("custom_field name: " + custom_field.name.to_s)
			Rails.logger.info("custom_field possible_values: " + custom_field.possible_values.to_s)
			custom_field.possible_values.each do |v|
				Rails.logger.info("value: " + v.to_s)
				index = v.to_s.index('-')
				if !index.nil? && index > 0 && v.to_s[0, index].to_i > 0
					item = [v.to_s, v.to_s[0, index].to_i]
					@items.push(item)
				end
			end
			@custom_field = custom_field
		end
	end
	
	def load_half_day_options
		@half_day_options = [[l(:general_text_No), 0], [l(:general_text_Yes), 1]]
	end

  def check_edit_rights
    right = User.current.allowed_to_globally?(:edit_national_holiday)
    if !right
      flash[:error] = translate 'no_right'
      redirect_to :back
    end
  end
  
 def select_year
   if (params[:year])
      @this_year=params[:year].to_i
    else 
      @this_year=Date.today.strftime("%Y").to_i if @this_year.blank?
    end
 end 
end
