class CleanupLocationTables < ActiveRecord::Migration[8.1]
  def change
    drop_table :place_names, if_exists: true, force: :cascade
    drop_table :places, if_exists: true, force: :cascade
    drop_table :administrative_divisions, if_exists: true, force: :cascade
    drop_table :cities, if_exists: true, force: :cascade
    drop_table :states, if_exists: true, force: :cascade
    drop_table :countries, if_exists: true, force: :cascade
  end
end
