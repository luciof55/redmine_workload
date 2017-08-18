class WlUserVacation < ActiveRecord::Base
  unloadable
  belongs_to :user
  attr_accessible :id, :user_id, :date_from, :date_to, :comments, :vacation_type
  validates_presence_of :user_id, :date_from, :date_to
  
  validates :date_from, :date => true
  validates :date_to, :date => true
  validate :check_datum, :check_overlapping
  
  after_save :clearCache
  after_destroy :clearCache  
  
  def check_datum
    if self.date_from && self.date_to && (date_from_changed? || date_to_changed?) && self.date_to < self.date_from
       errors.add :date_to, :workload_end_before_start 
    end 
  end
  
  def check_overlapping
	if WlUserVacation.where("id != ? AND user_id = ? AND date_from <= ? AND date_to >= ?", self.id, self.user_id, self.date_to, self.date_to).empty?
		if !WlUserVacation.where("id != ? AND user_id = ? AND date_from <= ? AND date_to >= ?", self.id, self.user_id, self.date_from, self.date_from).empty?
			errors.add :date_from, :workload_overlapping 
		end
	else
		errors.add :date_to, :workload_overlapping 
	end
  end
  
private
  def clearCache
    Rails.cache.clear
  end
end