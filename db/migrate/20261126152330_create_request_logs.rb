class CreateRequestLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :request_logs do |t|
      # The filter applied, e.g. "long_titles" / "short_titles". Not `type`,
      # which Rails reserves for Single Table Inheritance.
      t.string :filter_type, null: false
      # Nullable so anonymous (not signed-in) requests can still be logged.
      t.references :user, null: true, foreign_key: true

      # created_at doubles as the request timestamp.
      t.timestamps
    end
    add_index :request_logs, [ :filter_type, :created_at ]
  end
end
