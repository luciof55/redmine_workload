class WlNationalHoliday < ActiveRecord::Base
  unloadable
  attr_accessible :start_holliday
  attr_accessible :end_holliday
  attr_accessible :reason
  attr_accessible :place
  attr_accessible :half_day
  
  validates :start_holliday, :date => true
  validates_presence_of :start_holliday, :reason
  
  after_save :clearCache
  after_destroy :clearCache
  
  private
  
  def clearCache
    Rails.cache.clear
  end
end
