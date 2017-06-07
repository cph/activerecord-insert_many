require "activerecord/insert_many/version"
require "active_record"
require "active_record/connection_adapters/abstract_adapter"
require "active_record/fixtures"

module ActiveRecord
  module InsertMany
    def insert_many(fixtures, options={})
      connection.insert_many(fixtures, table_name, options)
    end
  end

  module InsertManyStatement
    def insert_many(fixtures, table_name=self.table_name, options={})
      returning = options[:returning]
      if returning
        raise ArgumentError, "To use :returning, you must be using Postgres" unless supports_returning?
      elsif supports_returning?
        primary_keys = schema_cache.primary_keys(table_name)
        returning = Array(primary_keys) if primary_keys
      end
      return returning && [] if fixtures.empty?

      sql = insert_many_sql(fixtures, table_name, options.merge(returning: returning))

      result = execute sql, "Fixture Insert"

      returning ? result.to_a : result
    end

    def insert_many_sql(fixtures, table_name, options={})
      returning = options[:returning]

      columns = schema_cache.columns_hash(table_name)

      sample = fixtures.first
      key_list = sample.map { |name, _value| quote_column_name(name) }
      returning = returning.map { |name| quote_column_name(name) } if returning

      value_lists = fixtures.map do |fixture|

        binds = fixture.map do |name, value|
          name = name.to_s
          if column = columns[name]
            type = lookup_cast_type_from_column(column)
            Relation::QueryAttribute.new(name, value, type)
          else
            raise Fixture::FixtureError, %(table "#{table_name}" has no column named #{name.inspect}.)
          end
        end

        binds.map(&:value_for_database).map do |value|
          begin
            quote(value)
          rescue TypeError
            quote(YAML.dump(value))
          end
        end
      end

      sql = "INSERT INTO #{quote_table_name(table_name)} (#{key_list.join(",")}) VALUES #{value_lists.map { |value| "(#{value.join(",")})" }.join(", ")}"

      if conflict = options[:on_conflict]
        raise ArgumentError, "To use the :on_conflict option, you must be using Postgres >= 9.5" unless supports_on_conflict?

        conflict_columns = Array.wrap(conflict.fetch(:column, schema_cache.primary_keys(table_name)))
        raise ArgumentError, "To use the :on_conflict option, you must specify :column" unless conflict_columns.any?

        conflict_do = conflict.fetch(:do)
        raise ArgumentError, "#{conflict_do.inspect} is an unknown value for conflict[:do]; must be :nothing or :update" unless [:nothing, :update].member?(conflict_do)

        conflict_columns = conflict_columns.map(&method(:quote_column_name))
        sql << " ON CONFLICT(#{conflict_columns.join(",")})"
        sql << " WHERE #{conflict[:where]}" if conflict[:where]

        if conflict_do == :nothing
          sql << " DO NOTHING"
        else
          sql << " DO UPDATE SET #{(key_list - conflict_columns).map { |key| "#{key} = excluded.#{key}" }.join(", ")}"
        end
      end

      sql << " RETURNING #{returning.join(",")}" if returning

      sql
    end

    def supports_on_conflict?
      self.class.name == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter" && postgresql_version >= 90500
    end

    def supports_returning?
      self.class.name == "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
    end
  end

end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, ActiveRecord::InsertManyStatement
ActiveRecord::Base.extend ActiveRecord::InsertMany
