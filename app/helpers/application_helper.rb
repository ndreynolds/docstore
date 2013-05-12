module ApplicationHelper

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column.to_s ? "current #{sort_direction}" : nil
    direction = column == sort_column.to_s && sort_direction.to_s == 'asc' ? 'desc' : 'asc'
    new_params = params.except(:offset).merge(sort: column, direction: direction)
    link_to title, new_params, class: css_class
  end

end
