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
  end

end
