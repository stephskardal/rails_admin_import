DummyApp::Application.routes.draw do
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
  root to: 'rails_admin/main#dashboard'
end
