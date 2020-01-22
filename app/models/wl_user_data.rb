class WlUserData < ActiveRecord::Base
  unloadable
  belongs_to :user
  validates_presence_of :user_id, :threshold_lowload_min, :threshold_normalload_min, :threshold_highload_min
  self.table_name = "wl_user_datas"

end