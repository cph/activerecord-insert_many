ActiveRecord::Schema.define(:version => 1) do

  create_table "books", :force => true do |t|
    t.string :title
    t.string :author

    t.string :isbn
    t.datetime :published_on

    t.index :isbn, where: "published_on IS NOT NULL", unique: true
  end

end
