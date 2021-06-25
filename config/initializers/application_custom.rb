module Consul
  class Application < Rails::Application
    unless Rails.env.test?
      config.i18n.default_locale = :es
      config.i18n.available_locales = [:es]
      config.i18n.enforce_available_locales = false
    end
  end
end
