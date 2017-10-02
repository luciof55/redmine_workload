# -*- encoding : utf-8 -*-
class DateTools

  # Returns a list of all regular working weekdays.
  # 1 is monday, 7 is sunday (same as in Date::cwday)
  def self.getWorkingDays()
    result = Set::new

	non_working_week_days = Setting['non_working_week_days']
	#Rails.logger.info("------------------------non_working_week_days: " + non_working_week_days.to_s)
	
    result.add(1) if !non_working_week_days.include?('1')
    result.add(2) if !non_working_week_days.include?('2')
    result.add(3) if !non_working_week_days.include?('3')
    result.add(4) if !non_working_week_days.include?('4')
    result.add(5) if !non_working_week_days.include?('5')
    result.add(6) if !non_working_week_days.include?('6')
    result.add(7) if !non_working_week_days.include?('7')

	#Rails.logger.info("------------------------result: " + result.to_s)
	
    return result
  end
  
  def self.getWorkingDaysInTimespan(timeSpan, user = 'all', noCache = false)
    raise ArgumentError unless timeSpan.kind_of?(Range)
    
    Rails.cache.clear if noCache
    
    return Rails.cache.fetch("#{user}/#{timeSpan}", expires_in: 12.hours) do
    
      workingDays = self::getWorkingDays()    
  
      result = Set::new
  
      timeSpan.each do |day|#
        next if self::IsVacation(day, user) ##skip Vacation
        next if self::IsHoliday(day) ##skip Holidays
  
        if workingDays.include?(day.cwday) then
          result.add(day)
        end
      end

      result      
    end 

  end

  def self.getRealDistanceInDays(timeSpan, assignee='all')
    raise ArgumentError unless timeSpan.kind_of?(Range)    
    return self::getWorkingDaysInTimespan(timeSpan, assignee).size
  end
    
  def self.IsHoliday(day)
    if WlNationalHoliday.where("start_holliday <= ? AND end_holliday >= ?", day, day).empty? then
      return false
    else
      return true
    end
  end
  
  def self.IsVacation(day, user)
    return false if user=='all'
    
    if WlUserVacation.where("user_id = ? AND date_from <= ? AND date_to >= ?", user, day, day).empty? then
      return false
    else
      return true
    end
  end
  
end
