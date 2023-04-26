class CreateWebhooks < ActiveRecord::Migration[4.2]
  def change
    create_table :webhooks do |t|
      t.string :url, :null => false
      t.string :key, :null => true
      t.boolean :subprojects, :default => :yes
      t.integer :project_id
    end
  end
end
