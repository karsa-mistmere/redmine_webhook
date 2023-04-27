class AddWebhookSecretKey < ActiveRecord::Migration[4.2]
    def change
      add_column :webhooks, :secret_key, :string, :null => true
      add_column :webhooks, :hmac_alg, :string, :default => 'sha256'
      add_column :webhooks, :subprojects, :boolean, :default => false
    end
  end