class UpdateWlNationalHolidays < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :wl_national_holidays, :place, :integer, :null => true
	add_column :wl_national_holidays, :half_day, :integer, :null => true
  end
end
