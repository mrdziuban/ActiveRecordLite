require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  attr_reader :other_class, :primary_key, :foreign_key, :other_class_name

  def other_class
    @other_class_name.constantize
  end

  def other_table
    other_class.table_name
  end
end

class BelongsToAssocParams < AssocParams
  def initialize(name, params)
    @other_class_name = params[:class_name] ||= name.camelize
    @primary_key = params[:primary_key] ||= "id"
    @foreign_key = params[:foreign_key] ||= "#{name}_id"
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  def initialize(name, params, self_class)
    @other_class_name = params[:class_name] ||= name.to_s.singularize.camelize
    @primary_key = params[:primary_key] ||= "id"
    @foreign_key = params[:foreign_key] ||= "#{self_class.underscore}_id"
  end

  def type
  end
end

module Associatable
  def assoc_params
  end

  def belongs_to(name, params = {})
    p name
    p params
    x = BelongsToAssocParams.new(name, params)

    define_method(name) do
      query = <<-SQL
        SELECT *
        FROM #{x.other_table}
        WHERE id = ?
      SQL

      x.other_class.parse_all(DBConnection.execute(query, self.send(x.foreign_key)))
    end
  end

  def has_many(name, params = {})
    x = HasManyAssocParams.new(name, params, self.class)
    define_method(name) do
      query = <<-SQL
        SELECT *
        FROM #{x.other_table}
        WHERE #{x.foreign_key} = ?
      SQL

      x.other_class.parse_all(DBConnection.execute(query, self.id))
    end
  end

  def has_one_through(name, assoc1, assoc2)
  end
end
