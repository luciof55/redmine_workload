class WlUserVacationsController < ApplicationController
  helper :work_load
  
  before_action :check_edit_rights, only: [:edit, :update, :create, :destroy, :new]
  
  def index
    @is_allowed = User.current.allowed_to_globally?(:edit_user_vacations)
    @wl_user_vacation = WlUserVacation.joins(:user)
  end
  
  def new
    @usersToDisplay = User.all.sort_by { |n| n[:lastname] }
	@wl_user_vacation = WlUserVacation.new
  end
  
  def edit
	@usersToDisplay = User.all.sort_by { |n| n[:lastname] }
    @wl_user_vacation = WlUserVacation.find(params[:id]) rescue nil 
  end    
  
  def update
	@wl_user_vacation = WlUserVacation.find(params[:id]) rescue nil 
	respond_to do |format|
	  if @wl_user_vacation.update_attributes(params[:wl_user_vacation])
		format.html { 
			flash[:notice] = 'Vacation was successfully updated.'
			redirect_to(:action => 'index', :params => { :year =>params[:year]} )
		}
		format.xml  { head :ok }
	  else
		format.html {
		  flash[:error] = "<ul>" + @wl_user_vacation.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>" 
		  redirect_to(:action => 'edit') }
		format.xml  { render :xml => @wl_user_vacation.errors, :status => :unprocessable_entity }
	  end
	end
  end
  
  def create
	@wl_user_vacation = WlUserVacation.new(params[:wl_user_vacations])
	if @wl_user_vacation.save
		flash[:notice] = 'Vacation was successfully saved.'
		redirect_to action: 'index', year: params[:year]
	else
		respond_to do |format| 
			format.html {
			  flash[:error] = "<ul>" + @wl_user_vacation.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>"
			  redirect_to(:action => 'new') }
			format.api  { render_validation_errors(@wl_user_vacation) }
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