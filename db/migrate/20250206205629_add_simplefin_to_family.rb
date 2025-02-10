class AddSimplefinToFamily < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :simplefin_access_url, :string
  end
end
