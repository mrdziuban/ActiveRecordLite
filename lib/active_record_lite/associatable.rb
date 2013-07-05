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
    @other_class_name = params[:class_name] ||= name.to_s.camelize
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
    @assoc_params.nil? ? @assoc_params = {} : @assoc_params
  end

  def belongs_to(name, params = {})
    assoc_params[name] = BelongsToAssocParams.new(name, params)

    define_method(name) do
      query = <<-SQL
        SELECT *
        FROM #{self.class.assoc_params[name].other_table}
        WHERE id = ?
      SQL

      self.class.assoc_params[name].other_class.parse_all(DBConnection.execute(query, self.send(self.class.assoc_params[name].foreign_key)))
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

  # :house, :human, :house
  # Cat has a house, because cat has a human and human has a house
  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      a1 = self.class.assoc_params[assoc1]
      a2 = a1.other_class.assoc_params[assoc2]

      # Select all house info from houses
      # Cat's cats.owner_id = humans.id
      # humans.house_id = houses.id
      query = <<-SQL
        SELECT x.*
        FROM #{a2.other_class.table_name} AS x
        JOIN #{a1.other_class.table_name} AS y
        ON y.#{a2.foreign_key} = x.#{a2.primary_key}
        JOIN #{self.class.table_name} AS z
        ON z.#{a1.foreign_key} = y.#{a1.primary_key}
        WHERE z.id = ?
      SQL

      a2.other_class.parse_all(DBConnection.execute(query, self.id))
    end
  end
end
