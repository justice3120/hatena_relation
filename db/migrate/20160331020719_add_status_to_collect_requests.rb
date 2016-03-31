class AddStatusToCollectRequests < ActiveRecord::Migration
  def change
    add_column :collect_requests, :status, :string
  end
end
