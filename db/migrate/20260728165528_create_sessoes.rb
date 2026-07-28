class CreateSessoes < ActiveRecord::Migration[8.0]
  def change
    create_table :sessoes do |t|
      t.references :usuario, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
