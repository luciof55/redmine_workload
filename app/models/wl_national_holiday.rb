class WlNationalHoliday < ActiveRecord::Base
  unloadable
  
  validates :start_holliday, :date => true
  validates_presence_of :start_holliday, :reason, :place
  validate :check_overlapping
  
  after_save :clearCache
  after_destroy :clearCache
  
	def gel_place
		if place
			custom_field = CustomField.where("name = 'Sede'").first
			if custom_field
				custom_field.possible_values.each do |v|
					index = v.to_s.index('-')
					if !index.nil? && index > 0 && v.to_s[0, index].to_i > 0 and v.to_s[0, index].to_i == place.to_i
						return v.to_s
					end
				end
			end
		end
		return ''
	end
  
  private
  
  def check_overlapping
	if self.id
		if WlNationalHoliday.where("id != ? AND place = ? AND start_holliday = ?", self.id, self.place, self.start_holliday).count > 0
			errors.add :start_holliday, :workload_overlapping 
		end
	else
		if WlNationalHoliday.where("place = ? AND start_holliday = ?", self.place, self.start_holliday).count > 0
			errors.add :start_holliday, :workload_overlapping 
		end
	end
  end
  
  def clearCache
    Rails.cache.clear
  end
end
