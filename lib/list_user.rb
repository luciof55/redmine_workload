# -*- encoding : utf-8 -*-
class ListUser

  require 'dateTools'
  
  def self.getProgress(issue, timeSpan)
	
	journalDatails = JournalDetail.joins(:journal).where({ journals: { journalized_id: issue.id}}).where({ journals: { journalized_type: "Issue"}}).where(property: "attr").where(prop_key: "done_ratio").where({ journals: { created_on: timeSpan}}).merge(Journal.order(:id))
	
	#Journal.joins(:details).where(journalized_id: issue.id).where(journalized_type: "Issue").where(journalized_type: 'Issue').where({ journal_details: { property: "attr" }}).where({ journal_details: { prop_key: "done_ratio" }}).where(created_on: timeSpan).order(:id)
	
	done_ratio = 0
	if (journalDatails.length > 0)
		initial = journalDatails[0].old_value
		final = journalDatails[journalDatails.length-1].value
		done_ratio = final.to_f - initial.to_f
		Rails.logger.info("Done ratio: " + done_ratio.to_s)
		if (done_ratio < 0)
			done_ratio = 0
		end
	else
		Rails.logger.info("No journals find!")
	end
	
	return done_ratio
	
  end

  def self.getEstimatedTimeForIssue(issue, timeSpan)
    raise ArgumentError unless issue.kind_of?(Issue)

    return 0.0 if issue.estimated_hours.nil?
    return 0.0 if issue.children.any?

	done_ratio = ListUser::getProgress(issue, timeSpan)
	
    return issue.estimated_hours * (done_ratio/100.00)
	#return issue.estimated_hours
  end
  
  def self.getEstimatedTimeForIssueForWorkload(issue, timeSpan)
    raise ArgumentError unless issue.kind_of?(Issue)

    return 0.0 if issue.estimated_hours.nil?
    return 0.0 if issue.children.any?
	
    return issue.estimated_hours
  end

  # Returns all issues that fulfill the following conditions:
  #  * They are open
  #  * The project they belong to is active
  def self.getOpenIssuesForUsers(users, exclude_closed, timeSpan)
    raise ArgumentError unless users.kind_of?(Array)
    userIDs = users.map(&:id)

    issue = Issue.arel_table
    project = Project.arel_table
    issue_status = IssueStatus.arel_table
	
	projectsId = Setting['plugin_redmine_workload']['projects'].split(",")

    if exclude_closed
		# Fetch only open issues 
		issues = Issue.joins(:project).joins(:status).joins(:assigned_to).where(issue[:assigned_to_id].in(userIDs)).where(project[:id].in(projectsId)).where(issue_status[:is_closed].eq(false)).where("start_date between ? and ? or due_date between ? and ?", timeSpan.first, timeSpan.last, timeSpan.first, timeSpan.last)
	else
		# Fetch all issues
		issues = Issue.joins(:project).joins(:assigned_to).where(issue[:assigned_to_id].in(userIDs)).where(project[:id].in(projectsId)).where("start_date between ? and ? or due_date between ? and ?", timeSpan.first, timeSpan.last, timeSpan.first, timeSpan.last) 
	end
    #  Filter out all issues that have children; They do not *directly* add to
    # the workload
    return issues.select { |x| x.leaf? }
  end

  # Returns the hours per day for the given issue. The result is only computed
  # for days in the given time span. The function assumes that firstDay is
  # today, so all remaining hours need to be done on or after firstDay.
  # If the issue is overdue, all hours are assigned to the first working day
  # after firstDay, or to firstDay itself, if it is a working day.
  #
  # The result is a hash taking a Date as key and returning a hash with the
  # following keys:
  #   * :hours - the hours needed on that day
  #   * :active - true if the issue is active on that day, false else
  #   * :noEstimate - no estimated hours calculated because the issue has
  #                   no estimate set or either start-time or end-time are not
  #                   set.
  #   * :holiday - true if this is a holiday, false otherwise.
  #
  # If the given time span is empty, an empty hash is returned.
  def self.getHoursForIssuesPerDay(issue, timeSpan, today, workload)
  
	Rails.logger.info("issue: " + issue.id.to_s + "star******************************************************")

    raise ArgumentError unless issue.kind_of?(Issue)
    raise ArgumentError unless timeSpan.kind_of?(Range)
    raise ArgumentError unless today.kind_of?(Date)

	if (workload)
		hoursRemaining = ListUser::getEstimatedTimeForIssueForWorkload(issue, timeSpan)
	else
	    hoursRemaining = ListUser::getEstimatedTimeForIssue(issue, timeSpan)
	end
    issue.assigned_to.nil? ? assignee = 'all' : assignee = issue.assigned_to
    workingDays = DateTools::getWorkingDaysInTimespan(timeSpan, assignee)    
	
	Rails.logger.info("issue: " + issue.id.to_s + " hoursRemaining: " + hoursRemaining.to_s + " assignee: " + assignee.to_s + " - workingDays: " + workingDays.to_s)
    
	result = Hash::new
	
	if issue.due_date && issue.start_date && issue.estimated_hours 
		# Number of remaining working days for the issue:
		numberOfWorkdaysForIssue = DateTools::getRealDistanceInDays(issue.start_date..issue.due_date, assignee)
        Rails.logger.info("issue: " + issue.id.to_s + " - numberOfWorkdaysForIssue: " + numberOfWorkdaysForIssue.to_s)
		hoursPerWorkday = hoursRemaining/numberOfWorkdaysForIssue.to_f
		timeSpan.each do |day|
			isHoliday = !workingDays.include?(day)
			if (day >= issue.start_date) && (day <= issue.due_date) then
				if isHoliday
					result[day] = {:hours => 0.0, :active => true, :noEstimate => false, :holiday => isHoliday, :clss => 'nwday'}
				else
					result[day] = {:hours => hoursPerWorkday, :active => true, :noEstimate => false, :holiday => isHoliday, :clss => 'normal'}
				end
			else
				result[day] = {:hours => 0.0, :active => false, :noEstimate => false, :holiday => isHoliday, :clss => 'normal'}
			end
		end
	end
	
	Rails.logger.info("issue: " + issue.id.to_s + "******************************************************end")

    return result
  end
  
  def self.getHoursForIssuesPerWeek(issue, timeSpan, today, first_day, last_day, workload)
	hoursForIssuesPerDay = getHoursForIssuesPerDay(issue, timeSpan, today, workload)
	week_start = first_day
	week_end = first_day + (7 - first_day.cwday)
	result = Hash::new
	
	while week_start <= last_day do
		hours = 0.0
		timeSpan.each do |day|
			if hoursForIssuesPerDay[day] && week_start <= day && week_end >= day
				hours += hoursForIssuesPerDay[day][:hours]
			end
			break if day > week_end
		end
		result[week_start.cweek] = {:hours => hours, :holiday => false, :clss => 'normal', :start_date => week_start, :end_date => week_end}
		week_start = week_end + 1
		week_end = week_start + 6
	end
		
	return result
  end
  
  def self.getHoursForIssuesPerMonth(issue, timeSpan, today, first_day, last_day, monthsToRender, workload)
	hoursForIssuesPerDay = getHoursForIssuesPerDay(issue, timeSpan, today, workload)
	result = Hash::new
	
	monthsToRender.each do |month|
		hours = 0.0
		timeSpan.each do |day|
			if hoursForIssuesPerDay[day] && month[:first_day] <= day && month[:last_day] >= day
				hours += hoursForIssuesPerDay[day][:hours]
			end
			break if day > month[:last_day]
		end
		result[month] = {:hours => hours, :holiday => false, :clss => 'normal', :start_date => 	month[:first_day], :end_date => month[:last_day]}
	end
		
	return result
  end

  # Returns the hours per day in the given time span (including firstDay and
  # lastDay) for each open issue of each of the given users.
  # The result is returned as nested hash:
  # The topmost hash takes a user as key and returns a hash that takes an issue
  # as key. This second hash takes a project as key and returns another hash.
	# This third level hash returns a hash that was returned by
	# getHoursForIssuesPerDay. Additionally, it has two special keys:
	# * :invisible. Returns a summary of all issues that are not visible for the
	#								currently logged in user.
	#´* :total.     Returns a summary of all issues for the user that this hash is
	#								for.
  def self.getHoursPerUserIssueAndDay(issues, timeSpan, today, workload)
    raise ArgumentError unless issues.kind_of?(Array)
    raise ArgumentError unless timeSpan.kind_of?(Range)
    raise ArgumentError unless today.kind_of?(Date)
    result = {}

    issues.each do |issue|
		assignee = issue.assigned_to
		workingDays = DateTools::getWorkingDaysInTimespan(timeSpan, assignee)
		
		if !result.has_key?(issue.assigned_to)
			result[assignee] = {:overdue_hours => 0.0, :overdue_number => 0, :total => Hash::new, :invisible => Hash::new}
				timeSpan.each do |day|
				result[assignee][:total][day] = {:hours => 0.0, :holiday => !workingDays.include?(day), :clss => 'normal'}
			end
		end
			
		hoursForIssue = getHoursForIssuesPerDay(issue, timeSpan, today, workload)
		result[assignee][:total] = addIssueInfoToSummary(result[assignee][:total], hoursForIssue, timeSpan)
    end
	
	#Mark workload (normal, lower, over).
	result.keys.each do |assigneeKey|
		result[assigneeKey][:total].keys.each do |dayKey|
			user_workload_data = WlUserData.find_by user_id: assigneeKey.id
			if user_workload_data
				threshold_highload_min = user_workload_data.threshold_highload_min
				threshold_lowload_min = user_workload_data.threshold_lowload_min
			else
				threshold_highload_min = Setting['plugin_redmine_workload']['threshold_highload_min'].to_f
				threshold_lowload_min = Setting['plugin_redmine_workload']['threshold_lowload_min'].to_f
			end
			if result[assigneeKey][:total][dayKey][:hours] > threshold_highload_min
				result[assigneeKey][:total][dayKey][:clss] = 'over'
			else
				if result[assigneeKey][:total][dayKey][:hours] < threshold_lowload_min
					result[assigneeKey][:total][dayKey][:clss] = 'lower'
				end
			end
		end
	end

    return result
  end
  
  def self.getHoursPerUserIssueAndWeek(issues, timeSpan, today, first_day, last_day)
    raise ArgumentError unless issues.kind_of?(Array)
    raise ArgumentError unless timeSpan.kind_of?(Range)
    raise ArgumentError unless today.kind_of?(Date)
    result = {}

    issues.each do |issue|
		assignee = issue.assigned_to
		week_start = first_day
		week_end = first_day + (7 - first_day.cwday)
		
		if !result.has_key?(issue.assigned_to)
			result[assignee] = {:overdue_hours => 0.0, :overdue_number => 0, :total => Hash::new, :invisible => Hash::new}
			while week_start <= last_day do
				result[assignee][:total][week_start.cweek] = {:hours => 0.0, :holiday => false, :clss => 'normal', :start_date => week_start, :end_date => week_end}
				week_start = week_end + 1
				week_end = week_start + 6
			end
		end
			
		hoursForIssue = getHoursForIssuesPerWeek(issue, timeSpan, today, first_day, last_day)
		hoursForIssue.keys.each do |weekKey|
			result[assignee][:total][weekKey][:hours] += hoursForIssue[weekKey][:hours]
		end
    end
	
	#Mark workload (normal, lower, over).
	result.keys.each do |assigneeKey|
		result[assigneeKey][:total].keys.each do |weekKey|
			timeSpan = result[assigneeKey][:total][weekKey][:start_date]..result[assigneeKey][:total][weekKey][:end_date]
			days = DateTools::getRealDistanceInDays(timeSpan, assigneeKey)
			user_workload_data = WlUserData.find_by user_id: assigneeKey.id
			if user_workload_data
				threshold_highload_min = user_workload_data.threshold_highload_min
				threshold_lowload_min = user_workload_data.threshold_lowload_min
			else
				threshold_highload_min = Setting['plugin_redmine_workload']['threshold_highload_min'].to_f
				threshold_lowload_min = Setting['plugin_redmine_workload']['threshold_lowload_min'].to_f
			end
			if result[assigneeKey][:total][weekKey][:hours] >  threshold_highload_min * days
				result[assigneeKey][:total][weekKey][:clss] = 'over'
			else
				if result[assigneeKey][:total][weekKey][:hours] <  threshold_lowload_min * days
					result[assigneeKey][:total][weekKey][:clss] = 'lower'
				end
			end
		end
	end

    return result
  end
  
	def self.getHoursPerUserIssueAndMonth(issues, timeSpan, today, first_day, last_day, monthsToRender, workload)
		raise ArgumentError unless issues.kind_of?(Array)
		raise ArgumentError unless timeSpan.kind_of?(Range)
		raise ArgumentError unless today.kind_of?(Date)
		result = {}

		issues.each do |issue|
			assignee = issue.assigned_to
			
			if !result.has_key?(issue.assigned_to)
				result[assignee] = {:overdue_hours => 0.0, :overdue_number => 0, :total => Hash::new, :invisible => Hash::new}
				monthsToRender.each do |month|
					result[assignee][:total][month] = {:hours => 0.0, :holiday => false, :clss => 'normal', :start_date => month[:first_day], :end_date => month[:last_day]}
				end
			end
				
			hoursForIssue = getHoursForIssuesPerMonth(issue, timeSpan, today, first_day, last_day, monthsToRender, workload)
			hoursForIssue.keys.each do |monthKey|
				result[assignee][:total][monthKey][:hours] += hoursForIssue[monthKey][:hours]
			end
		end

		#Mark workload (normal, lower, over).
		result.keys.each do |assigneeKey|
			result[assigneeKey][:total].keys.each do |monthKey|
				timeSpan = result[assigneeKey][:total][monthKey][:start_date]..result[assigneeKey][:total][monthKey][:end_date]
				days = DateTools::getRealDistanceInDays(timeSpan, assigneeKey)
				user_workload_data = WlUserData.find_by user_id: assigneeKey.id
				if user_workload_data
					threshold_highload_min = user_workload_data.threshold_highload_min
					threshold_lowload_min = user_workload_data.threshold_lowload_min
				else
					threshold_highload_min = Setting['plugin_redmine_workload']['threshold_highload_min'].to_f
					threshold_lowload_min = Setting['plugin_redmine_workload']['threshold_lowload_min'].to_f
				end
				if result[assigneeKey][:total][monthKey][:hours] >  threshold_highload_min * days
					result[assigneeKey][:total][monthKey][:clss] = 'over'
				else
					if result[assigneeKey][:total][monthKey][:hours] <  threshold_lowload_min * days
						result[assigneeKey][:total][monthKey][:clss] = 'lower'
					end
				end
			end
		end

		return result
	end

	# Returns an array with one entry for each month in the given time span.
	# Each entry is a hash with two keys: :first_day and :last_day, having the
	# first resp. last day of that month from the time span as value.
	def self.getMonthsInTimespan(timeSpan)
		raise ArgumentError unless timeSpan.kind_of?(Range)
		# Abort if the given time span is empty.
		return [] unless timeSpan.any?
		firstOfCurrentMonth = timeSpan.first
		lastOfCurrentMonth  = [firstOfCurrentMonth.end_of_month, timeSpan.last].min
		result = []
		while firstOfCurrentMonth <= timeSpan.last do
			result.push({:first_day => firstOfCurrentMonth, :last_day  => lastOfCurrentMonth})
			firstOfCurrentMonth = firstOfCurrentMonth.beginning_of_month.next_month
			lastOfCurrentMonth  = [firstOfCurrentMonth.end_of_month, timeSpan.last].min
		end
		return result
	end

	# Returns the "load class" for a given amount of working hours on a single
	# day.
	def self.getLoadClassForHours(hours, user = nil)
		raise ArgumentError unless hours.respond_to?(:to_f)
		hours = hours.to_f

		#load defaults:
		lowLoad = Setting['plugin_redmine_workload']['threshold_lowload_min'].to_f
		normalLoad = Setting['plugin_redmine_workload']['threshold_normalload_min'].to_f
		highLoad = Setting['plugin_redmine_workload']['threshold_highload_min'].to_f

		if !user.nil?
			user_workload_data = WlUserData.find_by user_id: user.id
			if !user_workload_data.nil?
				lowLoad     = user_workload_data.threshold_lowload_min
				normalLoad  = user_workload_data.threshold_normalload_min
				highLoad    = user_workload_data.threshold_highload_min
			end
		end

		if hours < lowLoad then
			return "none"
		elsif hours < normalLoad then
			return "low"
		elsif hours < highLoad then
			return "normal"
		else
			return "high"
		end      
	end

	# Returns the list of all users the current user may display.
	def self.getUsersAllowedToDisplay()
		return [] if User.current.anonymous?
		return User.active if User.current.admin?
		result = [User.current]
		# Get all projects where the current user has the :view_project_workload
		# permission
		projects = Project.allowed_to(:view_project_workload)
		projects.each do |project|
			result += project.members.map(&:user)
		end
		return result.uniq
	end

	def self.getUsersOfGroups(groups)
		result = []
		groups.each do |grp|
			result += grp.users(&:users)
		end
		return result.uniq
	end

	def self.addIssueInfoToSummary(summary, issueInfo, timeSpan)
		workingDays = DateTools::getWorkingDaysInTimespan(timeSpan)
		summary = Hash::new if summary.nil?

		timeSpan.each do |day|
			if !summary.has_key?(day)
				summary[day] = {:hours => 0.0, :holiday => !workingDays.include?(day), :clss => 'normal'}
			end
			if issueInfo[day]
				#Rails.logger.info("day: " + day.to_s + " hours: " + issueInfo[day][:hours].to_s)
				summary[day][:hours] += issueInfo[day][:hours]
			end
		end
		return summary
	end
end
