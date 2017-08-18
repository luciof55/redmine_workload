class WlNationalHolidayController < ApplicationController
  unloadable
  require 'json'
 
  before_action :check_edit_rights, only: [:edit, :update, :create, :destroy]
  before_action :select_year 
  
  helper :work_load
  
  def index            
    filter_year_start=Date.new(@this_year,01,01)
    filter_year_end=Date.new(@this_year,12,31)
    @wl_national_holiday = WlNationalHoliday.where("start_holliday between ? AND ?", filter_year_start, filter_year_end)
    @is_allowed = User.current.allowed_to_globally?(:edit_national_holiday)
  end
  
  def new

  end
  
  def edit
    @wl_national_holiday = WlNationalHoliday.find(params[:id]) rescue nil 
  end    
  
  def update
    @wl_national_holiday = WlNationalHoliday.find(params[:id]) rescue nil 
    respond_to do |format|
	  new_params = params 
	  new_params[:wl_national_holiday]["end_holliday(1i)"] = params[:wl_national_holiday]["start_holliday(1i)"]
      new_params[:wl_national_holiday]["end_holliday(2i)"] = params[:wl_national_holiday]["start_holliday(2i)"]
	  new_params[:wl_national_holiday]["end_holliday(3i)"] = params[:wl_national_holiday]["start_holliday(3i)"]

      if @wl_national_holiday.update_attributes(new_params[:wl_national_holiday])
        format.html { redirect_to(:action => 'index', :notice => 'Holiday was successfully updated.', :params => { :year =>params[:year]} ) }
        format.xml  { head :ok }
      else
        format.html { 
          flash[:error] = "<ul>" + @wl_national_holiday.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>"
          render :action => "edit" }
        format.xml  { render :xml => @wl_national_holiday.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def create
    @wl_national_holiday = WlNationalHoliday.new(params[:wl_national_holiday])
	@wl_national_holiday.end_holliday = @wl_national_holiday.start_holliday 
    if @wl_national_holiday.save
      redirect_to action: 'index', notice: 'Holiday was successfully saved.', year: params[:year]
    else
      respond_to do |format| 
        format.html {
          flash[:error] = "<ul>" + @wl_national_holiday.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>" 
          render :new }
        format.api  { render_validation_errors(@wl_national_holiday) }
      end 
    end    
  end
  
  def destroy
    @wl_national_holiday = WlNationalHoliday.find(params[:id]) rescue nil
    @wl_national_holiday.destroy
    
    redirect_to(:action => 'index', :notice => 'Holiday was successfully deleted.', :year => params[:year])
  end


private

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
