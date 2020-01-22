class CreateWlUserVacations < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :wl_user_vacations do |t|      
      t.belongs_to :user, :index => true, :null => false
      t.column :date_from,   :date,     :null => false
      t.column :date_to,     :date,     :null => false
      t.column :comments,      :string,   :limit => 255
      t.column :vacation_type, :string,   :limit => 255
      t.column :ref_id,      :integer   # optional: for sync purpose with external system 
    end
  end
end