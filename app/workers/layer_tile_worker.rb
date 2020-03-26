class LayerTileWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  def perform(surface_layer_id, opts = {})
    surface_layer = SurfaceLayer.find(surface_layer_id)
    surface = surface_layer.surface
    n = surface_layer.surface_images.count
    n_pos = surface_layer.surface_images.pluck(:position).count 
    total n
    if n =! n_pos
      at 0, "reordering images..."
      surface.reorder_images
    end
    surface_layer.clean_tiles
    surface_layer.surface_images.reverse.each_with_index do |surface_image, index|
      if surface_image.wall
        at index, "#{surface_layer.name}/#{surface_image.image.name} ... (skipped)"
        next
      end
      at index, "#{surface_layer.name}/#{surface_image.image.name} ... #{index + 1}/#{n}"
      surface_image.clean_tiles
      surface_image.clean_warped_image
      surface_image.make_tiles(opts)
      surface_image.merge_tiles(opts)
    end    
    at n, "Tile making job for #{surface_layer.name} is done."
  end
end
