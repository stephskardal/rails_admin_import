class RailsAdminImport::BaseController < RailsAdmin::MainController
  layout 'rails_admin/application'

  def import
    @response = {}

    results = @abstract_model.model.run_import(params)
    @response[:notice] = results[:success].join("<br />").html_safe if results[:success].any?
    @response[:error] = results[:error].join("<br />").html_safe if results[:error].any?

    @action = RailsAdmin::Config::Actions.find(:import, {:controller => self, :abstract_model => @abstract_model, :object => @object})
  end
end
