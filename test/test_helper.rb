require "rubygems"

require "minitest/reporters/turn_reporter"
MiniTest::Reporters.use! Minitest::Reporters::TurnReporter.new

require "database_cleaner"
require "activerecord/insert_many"
require "shoulda/context"
require "support/book"
require "minitest/autorun"
require "pry"


system "psql -c 'create database activerecord_insert_many_test'"

ActiveRecord::Base.establish_connection(
  adapter: "postgresql",
  host: "localhost",
  database: "activerecord_insert_many_test",
  verbosity: "quiet")

load File.join(File.dirname(__FILE__), "support", "schema.rb")


DatabaseCleaner.strategy = :truncation
