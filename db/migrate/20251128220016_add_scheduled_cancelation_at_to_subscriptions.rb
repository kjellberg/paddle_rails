class AddScheduledCancelationAtToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :paddle_rails_subscriptions, :scheduled_cancelation_at, :datetime
  end
end

