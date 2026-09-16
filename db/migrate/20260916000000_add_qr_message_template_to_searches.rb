# db/migrate/20260916000000_add_qr_message_template_to_searches.rb

class AddQrMessageTemplateToSearches < ActiveRecord::Migration[8.1]
  def change
    add_column :searches, :qr_message_template, :text
  end
end
