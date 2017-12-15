# -*- encoding : utf-8 -*-
require 'redmine'
require_dependency 'dateTools'
require_dependency 'list_user'

Redmine::Plugin.register :redmine_workload do
  name 'Redmine workload plugin'
  author 'Lucio Ferrero'
  description 'This is a plugin for Redmine, originally developed by Rafael Calleja and Jost Baron. It ' +
              'displays the estimated number of hours users have to work to finish ' +
              'all their assigned issus on time.'
  version '0.0.1'
  url 'https://github.com/luciof55/'
  author_url 'https://www.linkedin.com/in/lucioferrero/'
    
  menu :top_menu, :WorkLoad, { :controller => 'work_load', :action => 'show' }, :caption => :workload_title,
    :if =>  Proc.new { User.current.logged? && User.current.allowed_to_globally?(:view_project_workload) }


  settings :partial => 'settings/workload_settings',
           :default => {
              'threshold_lowload_min'     => 0.1,
              'threshold_normalload_min'  => 7,
              'threshold_highload_min'    => 8.5,
           }
  project_module :redmine_workload do
	  permission :view_project_workload, :work_load => :show
	  permission :edit_national_holiday, :wl_national_holiday => [:create, :update, :destroy ]
	  permission :edit_user_vacations,   :wl_user_vacations   => [:create, :update, :destroy ]
	  permission :edit_user_data,        :wl_user_datas       => [:index, :create, :update, :destroy ]
  end
  
end

class RedmineToolbarHookListener < Redmine::Hook::ViewListener
   def view_layouts_base_html_head(context)
		 javascript_include_tag('slides', :plugin => :redmine_workload ) +
     stylesheet_link_tag('style', :plugin => :redmine_workload )
   end
end
