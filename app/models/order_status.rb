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

class OrderStatus < ActiveRecord::Base
  include Redmine::SafeAttributes

  attr_protected :id if ActiveRecord::VERSION::MAJOR <= 4
  safe_attributes 'name', 'position', 'color_name', 'is_closed', 'is_default', 'move_to'

  before_destroy :check_integrity
  Redmine::VERSION.to_s >= '3.3' ? acts_as_positioned : rcrm_acts_as_list

  after_save :update_default

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 30

  scope :sorted, lambda { order("#{table_name}.position ASC") }
  scope :named, lambda { |arg| where("LOWER(#{table_name}.name) = LOWER(?)", arg.to_s.strip) }

  def update_default
    OrderStatus.where('id <> ?', id).update_all(:is_default => false) if is_default?
  end

  # Returns the default status for new orders
  def self.default
    where(:is_default => true).first
  end

  def color_name
    return "#" + "%06x" % color unless color.nil?
  end

  def color_name=(clr)
    self.color = clr.from(1).hex
  end

  def <=>(status)
    position <=> status.position
  end

  def to_s; name end

  private

  def check_integrity
    raise "Can't delete status" if Order.where(:status_id => id).any?
  end
end
