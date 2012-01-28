class RailsAdminImport::BaseController < RailsAdmin::MainController
  def import
    results = @abstract_model.model.run_import(params)
    flash[:notice] = results[:success].join("<br />").html_safe if results[:success].any?
    flash[:error] = results[:error].join("<br />").html_safe if results[:error].any?

    redirect_to rails_admin.import_path(@abstract_model.to_param)
  end
end
