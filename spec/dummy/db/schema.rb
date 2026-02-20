ActiveRecord::Schema.define(version: 1) do
  create_table :users, force: true do |t|
    t.string :email
    t.string :name
    t.timestamps
  end

  create_table :orders, force: true do |t|
    t.decimal :total, precision: 10, scale: 2
    t.string :status
    t.references :user
    t.timestamps
  end
end
