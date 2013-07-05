require_relative './db_connection'

module Searchable
  def where(params = {})
    where_arr = []
    values = []
    params.each do |key, value|
      where_arr << "#{key} = ?"
      values << value
    end

    where_string = where_arr.join(" AND ")

    query = <<-SQL
      SELECT *
      FROM #{@table_name}
      WHERE #{where_string}
    SQL

    self.parse_all(DBConnection.execute(query, *values))
  end
end