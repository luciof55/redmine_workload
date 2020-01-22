class WlUserVacationsController < ApplicationController
  helper :work_load
  
  before_action :check_edit_rights, only: [:edit, :update, :create, :destroy, :new]
  
  def index
    @is_allowed = User.current.allowed_to_globally?(:edit_user_vacations)
    @wl_user_vacation = WlUserVacation.joins(:user)
  end
  
  def new
	Rails.logger.info("NEW")
    @usersToDisplay = User.all.sort_by { |n| n[:lastname] }
	@wl_user_vacation = WlUserVacation.new
	@wl_user_vacation.date_from = Date.today
	@wl_user_vacation.date_to = Date.today
  end
  
  def edit
	@usersToDisplay = User.all.sort_by { |n| n[:lastname] }
    @wl_user_vacation = WlUserVacation.find(params[:id]) rescue nil 
  end    
  
  def update
	user_vacation = WlUserVacation.find(params[:id]) rescue nil
	
	user_vacation.user_id = params[:wl_user_vacation][:user_id]
	user_vacation.comments = params[:wl_user_vacation][:comments]
	user_vacation.vacation_type = params[:wl_user_vacation][:vacation_type]
	user_vacation.date_from = params[:wl_user_vacation][:date_from]
	user_vacation.date_to = params[:wl_user_vacation][:date_to]
	
	if user_vacation.save
		flash[:notice] = 'Vacation was successfully updated.'
		redirect_to(:action => 'index', :params => { :year =>params[:year]} )
	else
		respond_to do |format|
			format.html {
				  flash[:error] = "<ul>" + user_vacation.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>" 
				  redirect_to(:action => 'edit') }
			format.xml  { render :xml => user_vacation.errors, :status => :unprocessable_entity }
			format.api  { render_validation_errors(user_vacation) }
		end
	end
  end
  
  def create
	user_vacation = WlUserVacation.new
	
	user_vacation.user_id = params[:wl_user_vacations][:user_id]
	user_vacation.comments = params[:wl_user_vacations][:comments]
	user_vacation.vacation_type = params[:wl_user_vacations][:vacation_type]
	user_vacation.date_from = params[:wl_user_vacations][:date_from]
	user_vacation.date_to = params[:wl_user_vacations][:date_to]
	
	if user_vacation.save
		flash[:notice] = 'Vacation was successfully saved.'
		redirect_to action: 'index', year: params[:year]
	else
		respond_to do |format| 
			format.html {
			  flash[:error] = "<ul>" + user_vacation.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>"
			  redirect_to(:action => 'new') }
			format.xml  { render :xml => user_vacation.errors, :status => :unprocessable_entity }
			format.api  { render_validation_errors(user_vacation) }
		end 
	end
  end
  
  def destroy
    @wl_user_vacation = WlUserVacation.find(params[:id]) rescue nil
    @wl_user_vacation.destroy
    flash[:notice] = 'Vacation was successfully deleted.'
    redirect_to(:action => 'index')
  end

private

  def check_edit_rights
    is_allowed = User.current.allowed_to_globally?(:edit_user_vacations)
    if !is_allowed
      flash[:error] = translate 'no_right'
      redirect_to :action => 'index'
    end
  end
end