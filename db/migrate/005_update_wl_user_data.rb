class UpdateWlUserData < Rails.version < '5.1' ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_column :wl_user_datas, :factor, :decimal, precision: 2, scale: 1, :null => true
  end
end
