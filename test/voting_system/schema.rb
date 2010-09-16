ActiveRecord::Schema.define do

  create_table "logins", :force => true do |t|
    t.string   "username"
    t.string   "password"
  end

  create_table "candidates", :force => true do |t|
    t.integer  "login_id"
    t.string   "role"
    t.integer  "sort_position"
  end

  create_table "voters", :force => true do |t|
    t.integer  "login_id"
    t.string   "role"
    t.integer  "sort_position"
  end

  create_table "internal_users", :force => true do |t|
    t.integer  "login_id"
    t.integer  "sort_position"
  end

end