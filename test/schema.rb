ActiveRecord::Schema.define(:version => 1) do
  create_table :posts do |t|
    t.string :title
    t.timestamps
  end

  create_table :post_translations do |t|
    t.references :post
    t.string :locale
    t.string :title
    t.text :text
    t.timestamps
  end
  
  create_table :comments do |t|
    t.references :post
    t.string :text
    t.timestamps
  end

  create_table :comment_translations do |t|
    t.references :comment
    t.string :locale
    t.text :text
    t.timestamps
  end
end
