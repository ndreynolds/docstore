module ApplicationHelper

  def sortable(column, title = nil)
    title ||= column.titleize
    logger.debug(sort_direction.to_s)
    logger.debug(sort_direction.to_s == "asc")
    css_class = column == sort_column.to_s ? "current #{sort_direction}" : nil
    direction = column == sort_column.to_s && sort_direction.to_s == "asc" ? "desc" : "asc"
    link_to title, {:sort => column, :direction => direction}, {:class => css_class}
  end

end
