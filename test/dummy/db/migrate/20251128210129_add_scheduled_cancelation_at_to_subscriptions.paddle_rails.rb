# This migration comes from paddle_rails (originally 20251128220016)
class AddScheduledCancelationAtToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :paddle_rails_subscriptions, :scheduled_cancelation_at, :datetime
  end
end

