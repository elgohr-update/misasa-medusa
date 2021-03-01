class AddLeftRightUpperBottomToSurfaceImage < ActiveRecord::Migration[4.2]
  def change
    add_column :surface_images, :left, :float
    add_column :surface_images, :right, :float
    add_column :surface_images, :upper, :float
    add_column :surface_images, :bottom, :float
  end
end
