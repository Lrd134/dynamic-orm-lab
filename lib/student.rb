require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'interactive_record.rb'
require 'pry'

class Student < InteractiveRecord

  def initialize(options={})
    options.each do |property, value|
      self.send("#{property}=", value)
    end
  end

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    sql = <<-SQL
      PRAGMA table_info('#{table_name}')
    SQL
    table = DB[:conn].execute(sql)
    columns = []
    table.each do |column|
        columns << column["name"]
    end
    columns.compact
  end

  self.column_names.each do |col_name|
    attr_accessor col_name.to_sym
  end

  def table_name_for_insert
    Student.table_name
  end

  def col_names_for_insert
    col = []
    Student.column_names.each do |column|
        if !column.include?("id")
            col << column
        end
    end
    col.join(", ")
  end

  def values_for_insert
    "\'#{self.name}\', " "\'#{self.grade}\'"
  end

  def save
    values_arr = values_for_insert.delete("'").split(", ")
    sql = <<-SQL
    INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (?, ?)
    SQL
    DB[:conn].execute(sql, values_arr[0], values_arr[1])
    
    
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]   
  end

  def self.find_by_name(name)
    sql = <<-SQL
    SELECT * FROM #{self.table_name}
    WHERE name == ?
    SQL
    DB[:conn].execute(sql, name)
  end
  def self.find_by(attribute)
    if attribute.has_key?(:name)
      self.find_by_name(attribute[:name])
    elsif attribute.has_key?(:grade)
      sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE grade == ?
      SQL
      DB[:conn].execute(sql, attribute[:grade])
    elsif attribute.is_a?(Integer)
      sql = <<-SQL
      SELECT * FROM #{self.table_name}
      WHERE id == ?
      SQL
      DB[:conn].execute(sql, attribute)
    end
  end
end