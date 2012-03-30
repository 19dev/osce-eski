class AddUserOnPosts < ActiveRecord::Migration
  def up
    add_column :posts, :user_id, :integer
  end

  def down
  end
end
