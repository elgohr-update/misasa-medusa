class NestedResources::BibsController < ApplicationController

  respond_to :html, :xml, :json
  before_action :find_resource
  load_and_authorize_resource

  def index
    @bibs = @parent.bibs
    respond_with @bibs
  end

  def create
    @bib = Bib.new(bib_params)
    @parent.bibs << @bib if @bib.save
    respond_with @bib, location: adjust_url_by_requesting_tab(request.referer), action: "error"
  end

  def update
    @bib = Bib.find(params[:id])
    @parent.bibs << @bib
    respond_with @bib, location: adjust_url_by_requesting_tab(request.referer)
  end

  def destroy
    @bib = Bib.find(params[:id])
    @parent.bibs.delete(@bib)
    respond_with @bib, location: adjust_url_by_requesting_tab(request.referer)
  end

  def link_by_global_id
    @bib = Bib.joins(:record_property).where(record_properties: {global_id: params[:global_id]}).readonly(false).first
    @parent.bibs << @bib if @bib
    respond_with @bib, location: adjust_url_by_requesting_tab(request.referer), action: "error"
  rescue
    duplicate_global_id
  end

  private

  def bib_params
    params.require(:bib).permit(
      :entry_type,
      :abbreviation,
      :name,
      :journal,
      :year,
      :volume,
      :number,
      :pages,
      :month,
      :note,
      :key,
      :link_url,
      :doi,
      :user_id,
      :group_id,
      author_ids: [],
      record_property_attributes: [
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
        :published_at
      ]
    )
  end

  def find_resource
    resource_name = params[:parent_resource]
    resource_class = resource_name.camelize.constantize
    @parent = resource_class.find(params["#{resource_name}_id"])
  end

  def duplicate_global_id
    respond_to do |format|
      format.html { render "parts/duplicate_global_id", status: :unprocessable_entity }
      format.all { render body: nil, status: :unprocessable_entity }
    end
  end

end
