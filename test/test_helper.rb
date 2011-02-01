require 'rubygems'
require 'test/unit'
require 'active_support'
require "active_record"
require 'puret'
require 'logger'

ActiveRecord::Base.logger = Logger.new(nil)
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Migration.verbose = false
  load "schema.rb"
end
 
def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Post < ActiveRecord::Base
  has_many :comments, :dependent => :destroy
  accepts_nested_attributes_for :comments, :allow_destroy => true
  puret :title, :text
end

class PostTranslation < ActiveRecord::Base
  validates_uniqueness_of :title, :case_sensitive => false, :scope => [:post_id, :locale]
  puret_for :post
end

class Comment < ActiveRecord::Base
  belongs_to :post
  validates_presence_of :text
  puret :text
end

class CommentTranslation < ActiveRecord::Base
  validates_uniqueness_of :text, :case_sensitive => false, :scope => [:comment_id, :locale]
  puret_for :comment
end