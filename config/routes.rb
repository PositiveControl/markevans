Rails.application.routes.draw do
  # Health check endpoint for Kamal
  get "up" => "rails/health#show", as: :rails_health_check

  # SEO
  get "sitemap.xml", to: "home#sitemap", as: :sitemap, defaults: { format: "xml" }

  # Email preview in development
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Root path
  root "home#index"
end
