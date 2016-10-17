ActiveRecord::Schema.define(:version => 1) do

  create_table "books", :force => true do |t|
    t.string :title
    t.string :author
  end

end
