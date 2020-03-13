# -*- encoding : utf-8 -*-
class WlUserDatasController < ApplicationController
  helper :work_load
  
  before_action :check_edit_rights, only: [:edit, :update, :create, :destroy, :new]
  
	def index
		@is_allowed = User.current.allowed_to_globally?(:edit_user_data)
		@wl_users_data = WlUserData.joins(:user)
	end
  
	def new
		@usersToDisplay = User.all.sort_by { |n| n[:lastname] }
		@is_allowed = User.current.allowed_to_globally?(:edit_user_data)
		data=WlUserData.new
		data.threshold_lowload_min    = Setting['plugin_redmine_workload']['threshold_lowload_min']
		data.threshold_normalload_min = Setting['plugin_redmine_workload']['threshold_normalload_min']
		data.threshold_highload_min   = Setting['plugin_redmine_workload']['threshold_highload_min'] 
		data.factor   = Setting['plugin_redmine_workload']['factor'] 
		@wl_user_data = data
	end
	
	def create
		logger.info "Parameters: #{params.inspect}"
		if params[:wl_user_data][:user_id]
			#If data does exist update it
			aux = WlUserData.where user_id: params[:wl_user_data][:user_id]
			logger.info aux.size
			if aux.size > 0
				respond_to do |format| 
					@usersToDisplay = User.all.sort_by { |n| n[:lastname] }
					format.html {
						flash[:error] = "<ul>Data already exist</ul>"
						redirect_to(:action => 'new')
					}
				end
			else
				#If data does not exist create it
				logger.info "Se crea"
				user_data = WlUserData.new
				
				user_data.user_id = params[:wl_user_data][:user_id]
				user_data.threshold_lowload_min = params[:wl_user_data][:threshold_lowload_min]
				user_data.threshold_normalload_min = params[:wl_user_data][:threshold_normalload_min]
				user_data.threshold_highload_min = params[:wl_user_data][:threshold_highload_min]
				user_data.factor   = params[:wl_user_data][:factor]  
				
				if user_data.save
					flash[:notice] = 'Data was successfully saved.'
					redirect_to action: 'index' 
				else
					respond_to do |format| 
						format.html {
							flash[:error] = "<ul>" + user_data.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>"
							redirect_to(:action => 'new')
						}
					end 
				end
			end
		else
			respond_to do |format|
				format.html { 
						flash[:error] = "<ul>" + "Error: User cannot be empty" + "</ul>" 
						redirect_to(:action => 'new')
					}
			end
		end
	end
	
	def destroy
		if params[:id]
			begin
				@wl_user_data = WlUserData.find(params[:id]) 
				if @wl_user_data.destroy
					flash[:notice] = 'Data was successfully deleted.'
					redirect_to(:action => 'index')
				else
					respond_to do |format|
						format.html { 
							flash[:error] = "<ul>" + @wl_user_data.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>" 
							redirect_to(:action => 'index')
						}
					end
				end
			rescue => exception
				respond_to do |format|
					format.html { 
							flash[:error] = "<ul>" + "Error: User data not found" + "</ul>" 
							redirect_to(:action => 'index')
						}
				end
			end
		else
			respond_to do |format|
				format.html { 
						flash[:error] = "<ul>" + "Error: User param cannot be empty" + "</ul>" 
						redirect_to(:action => 'index')
					}
			end
		end
	end
	
	def edit
		@usersToDisplay = User.all.sort_by { |n| n[:lastname] }
		@is_allowed = User.current.allowed_to_globally?(:edit_user_data)
		if params[:id]
			begin
				@wl_user_data = WlUserData.find(params[:id]) 
			rescue => exception     
				respond_to do |format|
					format.html { 
							flash[:error] = "<ul>" + "Error: User data not found" + "</ul>" 
							redirect_to(:action => 'index')
						}
				end
			end
		else
			respond_to do |format|
				format.html { 
						flash[:error] = "<ul>" + "Error: User param cannot be empty" + "</ul>" 
						redirect_to(:action => 'index')
					}
			end
		end
	end
  
	def update
		logger.info "Parameters: #{params.inspect}"
		begin
			user_data = WlUserData.find(params[:id])
			respond_to do |format|
				
				user_data.threshold_lowload_min = params[:wl_user_data][:threshold_lowload_min]
				user_data.threshold_normalload_min = params[:wl_user_data][:threshold_normalload_min]
				user_data.threshold_highload_min = params[:wl_user_data][:threshold_highload_min]
				user_data.factor   = params[:wl_user_data][:factor] 
				
				if user_data.save
					format.html {
						flash[:notice]= l(:notice_account_updated)
						redirect_to(:action => 'index')
					}
				else
					format.html { 
						flash[:error] = "<ul>" + user_data.errors.full_messages.map{|o| "<li>" + o + "</li>" }.join("") + "</ul>" 
						redirect_to(:action => 'edit')
					}
				end
			end
		rescue => exception
			respond_to do |format|
				format.html { 
						flash[:error] = "<ul>" + "Error: User data not found" + "</ul>" 
						redirect_to(:action => 'index')
					}
			end
		end
	end

	private

	def check_edit_rights
		is_allowed = User.current.allowed_to_globally?(:edit_user_data)
		if !is_allowed
			flash[:error] = translate 'no_right'
			redirect_to :back
		end
	end
  
end