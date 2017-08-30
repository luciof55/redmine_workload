# -*- encoding : utf-8 -*-
class WorkLoadController < ApplicationController

  unloadable

  helper :gantt
  helper :issues
  helper :projects
  helper :queries
  helper :workload_filters
  
  include Redmine::Utils::DateCalculation
  include QueriesHelper

  def show
	if params[:exclude_closed] && params[:exclude_closed] == '1'
		@exclude_closed = true
	else
		@exclude_closed = false
	end
	
	if params[:show_lower] && params[:show_lower] == '1'
		@show_lower = true
	else
		@show_lower = false
	end
	
	if params[:show_normal] && params[:show_normal] == '1'
		@show_normal = true
	else
		@show_normal = false
	end
	
	if params[:show_over] && params[:show_over] == '1'
		@show_over = true
	else
		@show_over = false
	end
	
	workloadOptions = {:show_lower => @show_lower, :show_normal => @show_normal, :show_over => @show_over}
	
	if params[:year] && params[:year].to_i > 0
		@year_from = params[:year].to_i
		if params[:month] && params[:month].to_i >=1 && params[:month].to_i <= 12
			@month_from = params[:month].to_i
		else
			@month_from = 1
		end
	else
		@month_from ||= User.current.today.month
		@year_from ||= User.current.today.year
	end
	
	if params[:months]
		months = (params[:months]).to_i
	else
		months = 6
	end
	@months = (months > 0 && months < 25) ? months : 6
    @first_day = Date.civil(@year_from, @month_from, 1)
    @last_day  = (@first_day >> @months) - 1
	if params[:control_date]
		@today = params[:control_date].to_date
	else
		@today = User.current.today
	end

	zoom = (params[:zoom] || User.current.pref[:wokload_zoom]).to_i
    @zoom = (zoom > 1 && zoom < 5) ? zoom : 2

	if User.current.logged? && @zoom != User.current.pref[:wokload_zoom]
		User.current.pref[:workload_zoom] = @zoom
		User.current.preference.save
    end
	  
	# if @today ("select as today") is before @first_day take @today as @first_day
	@today = [@today, @first_day].max
	
	# if @today ("select as today") is after @last_day take @today as @last_day
	@today = [@today, @last_day].min
	
    # Make sure that last_day is at most 12 months after first_day to prevent
    # long running times
    @last_day = [(@first_day >> 12) - 1, @last_day].min
    @timeSpanToDisplay = @first_day..@last_day

    initalizeUsers(params[:workload] || {})       
    
    @issuesForWorkload = ListUser::getOpenIssuesForUsers(@usersToDisplay, @exclude_closed)
    @monthsToRender = ListUser::getMonthsInTimespan(@timeSpanToDisplay)
	
	case @zoom
		when 4
			@show_days = true
			@show_weeks = true
			@show_months = true
			@workloadData   = ListUser::getHoursPerUserIssueAndDay(@issuesForWorkload, @timeSpanToDisplay, @today)
		when 3
			@show_days = false
			@show_weeks = true
			@show_months = true
			@workloadData   = ListUser::getHoursPerUserIssueAndWeek(@issuesForWorkload, @timeSpanToDisplay, @today, @first_day, @last_day)
		when 2
			@show_days = false
			@show_weeks = false
			@show_months = true
			@workloadData   = ListUser::getHoursPerUserIssueAndMonth(@issuesForWorkload, @timeSpanToDisplay, @today, @first_day, @last_day, @monthsToRender)
	end

  end

private

  def initalizeUsers(workloadParameters)
    @groupsToDisplay=Group.all.sort_by { |n| n[:lastname] }
    
    groupIds = workloadParameters[:groups].kind_of?(Array) ? workloadParameters[:groups] : []
    groupIds.map! { |x| x.to_i }
    
    # Find selected groups:
    @selectedGroups =Group.where(:id => groupIds)
    
    @selectedGroups = @selectedGroups & @groupsToDisplay
    
    @usersToDisplay=ListUser::getUsersOfGroups(@selectedGroups)

    # Get list of users that are allowed to be displayed by this user sort by lastname
    @usersAllowedToDisplay = ListUser::getUsersAllowedToDisplay().sort_by { |u| u[:lastname] }

    userIds = workloadParameters[:users].kind_of?(Array) ? workloadParameters[:users] : []
    userIds.map! { |x| x.to_i }

    # Get list of users that should be displayed.    
    @usersToDisplay += User.where(:id => userIds)

    # Intersect the list with the list of users that are allowed to be displayed.
    @usersToDisplay = @usersToDisplay & @usersAllowedToDisplay 
    @usersToDisplay.sort
  end
  

  def sanitizeDateParameter(parameter, default)

    if parameter.kind_of?(Date) then
      return parameter.to_date
    else
		flash[:error] = 'Date was corrected'
        return default
    end
  end
end
