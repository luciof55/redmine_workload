# -*- encoding : utf-8 -*-
module WorkloadFiltersHelper

	def wl_zoom_link(zoom, in_or_out)
		case in_or_out
		when :in
		  if zoom < 4
			link_to l(:text_zoom_in), {:params => request.query_parameters.merge({:zoom => (zoom + 1)})}, :class => 'icon icon-zoom-in'
		  else
			content_tag(:span, l(:text_zoom_in), :class => 'icon icon-zoom-in').html_safe
		  end

		when :out
		  if zoom > 2
			link_to l(:text_zoom_out), {:params => request.query_parameters.merge({:zoom => (zoom - 1)})}, :class => 'icon icon-zoom-out'
		  else
			content_tag(:span, l(:text_zoom_out), :class => 'icon icon-zoom-out').html_safe
		  end
		end
	end
  
  def get_option_tags_for_userselection(usersToShow, selectedUsers)

    result = '';

    usersToShow.each do |user|
      selected = selectedUsers.include?(user) ? 'selected="selected"' : ''

      result += "<option value=\"#{h(user.id)}\" #{selected}>#{h(user.name)}</option>"
    end

    return result.html_safe
  end

  def get_option_tags_for_groupselection(groupsToShow, selectedGroups)
    
    result = '';

    groupsToShow.each do |group|            
      
      selected = selectedGroups.include?(group) ? 'selected="selected"' : ''

     result += "<option value=\"#{h(group.id)}\" #{selected}>#{h(group.lastname)}</option>"
    
    end
    

    return result.html_safe
  end  
end
