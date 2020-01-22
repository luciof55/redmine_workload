class CreateWlNationalHolidays < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table  :wl_national_holidays do |t|
      t.date      :start_holliday,  :null => false
      t.date      :end_holliday,  :null => false
      t.string    :reason,  :null => false
    end
  end
end
