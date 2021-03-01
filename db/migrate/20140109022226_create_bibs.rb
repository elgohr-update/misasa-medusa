class CreateBibs < ActiveRecord::Migration[4.2]
  def change
    create_table :bibs do |t|
      t.string :entry_type
      t.string :abbreviation
      t.string :authorlist
      t.string :name
      t.string :journal
      t.string :year
      t.string :volume
      t.string :number
      t.string :pages
      t.string :month
      t.string :note
      t.string :key
      t.string :link_url
      t.text   :doi
      
      t.timestamps
    end
  end
end
