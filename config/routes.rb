Rails.application.routes.draw do
  devise_for :users
  # Health check endpoint for Kamal
  get "up" => "rails/health#show", as: :rails_health_check

  # SEO
  get "sitemap.xml", to: "home#sitemap", as: :sitemap, defaults: { format: "xml" }

  # Email preview in development
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # The site's other pages (design doc, section 2). Copy lives in content/
  # (docs/system/site-pages.md).
  resources :projects, path: "work", only: %i[index show]
  resource :workflow, only: :show
  resource :background, only: :show
  resource :contact, only: :show

  # Root path
  root "home#index"
end
