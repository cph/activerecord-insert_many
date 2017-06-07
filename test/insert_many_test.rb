require "test_helper"

class InsertManyTest < Minitest::Test

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end


  context "insert_many" do
    should "create records" do
      Book.insert_many [{title: "The Great Divorce", author: "C.S. Lewis"}]
      assert_equal 1, Book.count
    end

    should "return the primary key by default" do
      results = Book.insert_many [{title: "The Great Divorce", author: "C.S. Lewis"}]
      assert_equal [{"id" => 1}], results
    end

    should "return requested fields" do
      results = Book.insert_many [{title: "The Great Divorce", author: "C.S. Lewis"}], returning: [:id, :title]
      assert_equal [{"id" => 1, "title" => "The Great Divorce"}], results
    end

    context "when on_conflict = :nothing" do
      should "skip duplicate records" do
        Book.insert_many [{id: 1, title: "The Great Divorce", author: "C.S. Lewis"}]
        Book.insert_many [{id: 1, title: "Perelandra", author: "C.S. Lewis"}], on_conflict: { do: :nothing }
        assert_equal ["The Great Divorce"], Book.pluck(:title)
      end
    end

    context "when on_conflict = :update" do
      should "replace duplicate records" do
        Book.insert_many [{id: 1, title: "The Great Divorce", author: "C.S. Lewis"}]
        Book.insert_many [{id: 1, title: "Perelandra", author: "C.S. Lewis"}], on_conflict: { do: :update }
        assert_equal ["Perelandra"], Book.pluck(:title)
      end
    end

    context "when on_conflict.column is an array" do
      should "list all the columns in the ON CONFLICT clause" do
        assert_match /ON CONFLICT\("title","author"\)/, Book.connection.insert_many_sql(
          [{id: 1, title: "The Great Divorce", author: "C.S. Lewis"}],
          "books",
          on_conflict: { column: %i{title author}, do: :update })
      end
    end

    context "when on_conflict.where is provided" do
      should "perform the correct action based on a partial index" do
        Book.insert_many [{id: 1, title: "Out of the Silent Planet", author: "C.S. Lewis", isbn: "1974522598", published_on: Date.new(1938, 4, 1) }]
        Book.insert_many [{id: 2, title: "Perelandra", author: "C.S. Lewis", isbn: "1974522598", published_on: Date.new(1943, 1, 1) }], on_conflict: { column: :isbn, where: "published_on IS NOT NULL", do: :update }
        assert_equal ["Perelandra"], Book.where(isbn: "1974522598").pluck(:title)
      end

      should "not perform an UPSERT if a partial index doesn't apply" do
        Book.insert_many [{id: 1, title: "Out of the Silent Planet", author: "C.S. Lewis", isbn: "1974522598", published_on: Date.new(1938, 4, 1) }]
        Book.insert_many [{id: 2, title: "Perelandra", author: "C.S. Lewis", isbn: "1974522598" }], on_conflict: { column: :isbn, where: "published_on IS NOT NULL", do: :update }
        assert_equal ["Out of the Silent Planet", "Perelandra"], Book.where(isbn: "1974522598").pluck(:title).sort
      end

      should "include a WHERE clause in the ON CONFLICT clause" do
        assert_match /ON CONFLICT\("id"\) WHERE author IS NOT NULL/, Book.connection.insert_many_sql(
          [{id: 1, title: "Perelandra", author: "C.S. Lewis"}],
          "books",
          on_conflict: { column: :id, do: :nothing, where: "author IS NOT NULL" })
      end
    end
  end

end
