class RemoveCompletedToCollectRequests < ActiveRecord::Migration
  def change
    remove_column :collect_requests, :completed
  end
end
