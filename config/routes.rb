RailsAdminImport::Engine.routes.draw do
  scope :module => "rails_admin_import" do
    match ":model_name/import" => "base#import", :as => :import
  end
end
