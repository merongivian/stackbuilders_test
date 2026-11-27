class ReplaceUsersWithUserNameOnRequestLogs < ActiveRecord::Migration[8.1]
  # Callers identify themselves with a plain name (?user=jose) instead of an
  # account, so the users table goes and each log stores the name directly.
  def change
    # Existing rows get "anonymous" so the column can be NOT NULL; new rows
    # must always say who made the request.
    add_column :request_logs, :user_name, :string, null: false, default: "anonymous"
    change_column_default :request_logs, :user_name, from: "anonymous", to: nil
    add_index :request_logs, :user_name

    remove_reference :request_logs, :user, null: true, foreign_key: true, index: true

    drop_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.timestamps
      t.index :email, unique: true
    end
  end
end
