require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name
  end

  def self.table_name
    "#{@table_name}".underscore
  end

  def self.all
    query = <<-SQL
      SELECT *
      FROM #{@table_name}
    SQL

    self.parse_all(DBConnection.execute(query))
  end

  def self.find(id)
    query = <<-SQL
      SELECT *
      FROM #{@table_name}
      WHERE id = ?
    SQL

    self.parse_all(DBConnection.execute(query, id))[0]
  end

  def save
    self.id.nil? ? create : update
  end

  private

  def create
    question_marks_str = (['?'] * self.class.attributes.length).join(", ")
    attributes_string = self.class.attributes.join(", ")
    
    query = <<-SQL
      INSERT INTO #{self.class.table_name} (#{attributes_string})
      VALUES (#{question_marks_str})
    SQL

    DBConnection.execute(query, *attribute_values)

    self.send("#{:id}=", DBConnection.last_insert_row_id)
  end

  def update
    set_line = []
    self.class.attributes.each do |attr_name|
      set_line << "#{attr_name} = ?"
    end
    set_line = set_line.join(", ")

    query = <<-SQL
      UPDATE #{self.class.table_name}
      SET #{set_line}
      WHERE id = ?
    SQL
    puts query

    DBConnection.execute(query, *attribute_values, send(:id))
  end

  def attribute_values
    self.class.attributes.map{|attribute| send(attribute)}
    # values = []
    # self.class.attributes.each do |attribute|
    #   values << send(attribute)
    # end
  end
end
