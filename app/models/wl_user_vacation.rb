class WlUserVacation < ActiveRecord::Base
  unloadable
  belongs_to :user
  validates :user_id, :date_from, :date_to, presence: true
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
	if self.id
		if WlUserVacation.where("id != ? AND user_id = ? AND date_from <= ? AND date_to >= ?", self.id, self.user_id, self.date_to, self.date_to).empty?
			if !WlUserVacation.where("id != ? AND user_id = ? AND date_from <= ? AND date_to >= ?", self.id, self.user_id, self.date_from, self.date_from).empty?
				errors.add :date_from, :workload_overlapping 
			end
		else
			errors.add :date_to, :workload_overlapping 
		end
	else
		if WlUserVacation.where("user_id = ? AND date_from <= ? AND date_to >= ?", self.user_id, self.date_to, self.date_to).empty?
			if !WlUserVacation.where("user_id = ? AND date_from <= ? AND date_to >= ?", self.user_id, self.date_from, self.date_from).empty?
				errors.add :date_from, :workload_overlapping 
			end
		else
			errors.add :date_to, :workload_overlapping 
		end
	end
  end
  
private
  def clearCache
    Rails.cache.clear
  end
end