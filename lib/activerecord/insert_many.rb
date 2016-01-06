require "activerecord/insert_many/version"
require "active_record"
require "active_record/connection_adapters/abstract_adapter"

module ActiveRecord
  module InsertMany
    def insert_many(fixtures)
      connection.insert_many(fixtures, table_name)
    end
  end

  module InsertManyStatement
    def insert_many(fixtures, table_name=self.table_name)
      return if fixtures.empty?

      columns = schema_cache.columns_hash(table_name)

      sample = fixtures.first
      key_list = sample.map { |name, value| quote_column_name(name) }

      value_lists = fixtures.map do |fixture|
        fixture.map do |name, value|
          quote(value, columns[name.to_s])
        end
      end

      primary_key_column = schema_cache.primary_keys(table_name)
      returning = supports_returning? && primary_key_column.present? ? " RETURNING #{primary_key_column}" : ""

      execute "INSERT INTO #{quote_table_name(table_name)} (#{key_list.join(', ')}) VALUES #{value_lists.map { |value| "(#{value.join(', ')})" }.join(",")}#{returning}", "Fixture Insert"
    end

    def supports_returning?
      self.class.name == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
    end
  end

end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, ActiveRecord::InsertManyStatement
ActiveRecord::Base.extend ActiveRecord::InsertMany
