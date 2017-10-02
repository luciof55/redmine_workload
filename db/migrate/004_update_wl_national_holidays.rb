class UpdateWlNationalHolidays < ActiveRecord::Migration
  def change
    add_column :wl_national_holidays, :place, :integer, :null => true
	add_column :wl_national_holidays, :half_day, :integer, :null => true
  end
end
