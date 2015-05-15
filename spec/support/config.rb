def default_config
  RailsAdmin.config do |config|
    config.actions do
      all
      import
    end
  end
end
