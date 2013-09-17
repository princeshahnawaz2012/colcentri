Colcentric::Application.config.middleware.use OmniAuth::Builder do
  Colcentric.config.providers.each do |config|
    provider config[:provider].to_sym, config[:key], config[:secret]
  end
end if Colcentric.config.providers?
