class PlacesController < ApplicationController
  respond_to :html, :xml, :json, :kml
  before_action :find_resource, except: [:index, :new, :create, :bundle_edit, :bundle_update, :download_bundle_card, :download_label, :download_bundle_label, :import]
  before_action :find_resources, only: [:bundle_edit, :bundle_update, :download_bundle_card, :download_bundle_label]
  load_and_authorize_resource

  def index
    @search = Place.includes(:specimens).readables(current_user).ransack(params[:q])
    @search.sorts = "updated_at DESC" if @search.sorts.empty?
    @places = @search.result.page(params[:page]).per(params[:per_page])
    respond_with @places
  end

  def new
    respond_to do |format|
      format.csv { send_data(Place::TEMPLATE_HEADER, type: "text/csv", filename: "my_place.csv") }
    end
  end

  def show
    respond_with @place
  end

  def edit
    respond_with @place, layout: !request.xhr?
  end

  def create
    @place = Place.new(place_params)
    @place.save
    respond_with @place
  end

  def update
    @place.update(place_params)
    respond_with @place
  end

  def map
    respond_with @specimen, layout: !request.xhr?
  end

  def property
    respond_with @specimen, layout: !request.xhr?
  end

  def destroy
    @place.destroy
    respond_with @place
  end

  def bundle_edit
    respond_with @places
  end

  def bundle_update
    @places.each { |place| place.update(place_params.only_presence) }
    render :bundle_edit
  end

  def download_bundle_card
    method = (params[:a4] == "true") ? :build_a_four : :build_cards
    report = Place.send(method, @places)
    send_data(report.generate, filename: "places.pdf", type: "application/pdf")
  end

  def download_label
    place = Place.find(params[:id])
    send_data(place.build_label, filename: "place_#{place.id}.label", type: "text/label")
  end

  def download_bundle_label
    label = Place.build_bundle_label(@places)
    send_data(label, filename: "places.label", type: "text/label")
  end

  def import
    if Place.import_csv(params[:data])
      redirect_to places_path
    else
      render "import_invalid"
    end
  rescue
    render "import_invalid"
  end

  private

  def place_params
    params.require(:place).permit(
      :name,
      :description,
      :latitude,
      :latitude_dms_direction,
      :latitude_dms_deg,
      :latitude_dms_min,
      :latitude_dms_sec,
      :longitude,
      :longitude_dms_direction,
      :longitude_dms_deg,
      :longitude_dms_min,
      :longitude_dms_sec,
      :elevation,
      :link_url,
      :doi,
      :user_id,
      :group_id,
      :published,
      record_property_attributes: [
        :id,
        :global_id,
        :user_id,
        :group_id,
        :owner_readable,
        :owner_writable,
        :group_readable,
        :group_writable,
        :guest_readable,
        :guest_writable,
        :published,
        :lost
      ]

    )
  end

  def find_resource
    @place = Place.find(params[:id]).decorate
  end

  def find_resources
    @places = Place.where(id: params[:ids])
  end

end
