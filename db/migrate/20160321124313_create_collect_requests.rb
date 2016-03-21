class CreateCollectRequests < ActiveRecord::Migration
  def change
    create_table :collect_requests do |t|
      t.string :request_id
      t.boolean :completed
      t.text :result

      t.timestamps null: false
    end
  end
end
