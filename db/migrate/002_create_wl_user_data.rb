class CreateWlUserData < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    create_table :wl_user_datas do |t|
      t.belongs_to :user, index: true, :null => false      
      t.float   :threshold_lowload_min,     :null => false
      t.float   :threshold_normalload_min,  :null => false
      t.float   :threshold_highload_min,    :null => false
    end
  end
end