require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
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

    row_hashes = DBConnection.execute(query)

    row_hashes.each do |row_hash|
      self.new(row_hash)
    end
  end

  def self.find(id)
    query = <<-SQL
      SELECT *
      FROM #{@table_name}
      WHERE id = ?
    SQL

    DBConnection.execute(query, id)
  end

  def save
    p self.send(:id)
    if self.id.nil?
      create
    else
      update
    end
  end

  private

  def create
    question_marks_str = (['?'] * self.class.attributes.length).join(", ")
    attributes_string = self.class.attributes.join(", ")
    
    query = <<-SQL
      INSERT INTO #{self.class.table_name} (#{attributes_string})
      VALUES (#{question_marks_str})
    SQL

    puts "IN CREATE"

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

    puts "IN UPDATE"

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