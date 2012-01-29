class RailsAdminImport::BaseController < RailsAdmin::MainController
  def import
    @response = {}

    results = @abstract_model.model.run_import(params)
    @response[:notice] = results[:success].join("<br />").html_safe if results[:success].any?
    @response[:error] = results[:error].join("<br />").html_safe if results[:error].any?

    # TODO: Gross
    # * Can't use flash because cookie store 4kb method will likely be hit
    # * Can't redirect to rails_admin.import because we lose @response
    # * Can't call RailsAdmin::MainController.import because it's private
    # * So, method copied directly below
    @action = RailsAdmin::Config::Actions.find(:import, {:controller => self, :abstract_model => @abstract_model, :object => @object})
          
    @authorization_adapter.try(:authorize, @action.authorization_key, @abstract_model, @object)
    @page_name = wording_for(:title)
    @page_type = @abstract_model && @abstract_model.pretty_name.downcase || "dashboard"
          
    instance_eval &@action.controller
  end
end
