# This migration comes from paddle_rails (originally 20251127221947)
class CreatePaddleRailsWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :paddle_rails_webhook_events do |t|
      t.string :external_id, null: false
      t.string :event_type, null: false
      t.json :payload, null: false
      t.string :status, null: false, default: "pending"
      t.text :processing_errors
      t.datetime :processed_at

      t.timestamps
    end

    add_index :paddle_rails_webhook_events, :external_id, unique: true
    add_index :paddle_rails_webhook_events, :event_type
    add_index :paddle_rails_webhook_events, :status
  end
end

