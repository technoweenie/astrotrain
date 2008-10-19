migration 1, :add_mappings_destination  do
  up do
    modify_table :mappings do
      add_column :transport, String, :size => 255
      rename_column :post_url, :destination
    end
  end

  down do
    modify_table :mappings do
      drop_column :transport
      rename_column :destination, :post_url
    end
  end
end
