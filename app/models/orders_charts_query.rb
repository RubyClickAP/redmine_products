# This file is a part of Redmine Products (redmine_products) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2019 RedmineUP
# http://www.redmineup.com/
#
# redmine_products is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_products is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_products.  If not, see <http://www.gnu.org/licenses/>.

class OrdersChartsQuery < OrderQuery
  attr_reader :interval_size

  def initialize(attributes = nil)
    super
    filters['report_date_period'] = { operator: 'm', values: [''] } if filters['report_date_period'].blank?
  end

  def initialize_available_filters
    super
    delete_available_filter 'order_date'
    add_available_filter 'report_date_period', type: :date_past, label: :label_products_order_date
  end

  def orders(options = {})
    scope = Order.visible.includes((query_includes + (options[:include] || [])).uniq)
    options[:search].split(' ').collect { |search_string| scope = scope.live_search(search_string) } if options[:search].present?
    scope.where(statement).where(options[:conditions]).order(:order_date)
  end

  def build_from_params(params)
    if params[:fields] || params[:f]
      self.filters = {}
      add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
    else
      available_filters.keys.each do |field|
        add_short_filter(field, params[field]) if params[field]
      end
    end
    self.group_by = params[:group_by] || (params[:query] && params[:query][:group_by])
    self.column_names = params[:c] || (params[:query] && params[:query][:column_names])
    self.interval_size = params[:interval_size] if params[:interval_size]
    self
  end

  def interval_size=(value)
    allowed_values = %w(year quarter month week day)

    if allowed_values.include?(value)
      @interval_size = value
    else
      raise ArgumentError.new("value must be one of: #{allowed_values.join(', ')}")
    end
  end

  def sql_for_report_date_period_field(field, operator, values)
    sql_for_field(field, operator, values, Order.table_name, 'order_date')
  end
end
