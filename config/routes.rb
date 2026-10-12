Rails.application.routes.draw do
  # www is a second name for the site: everything on it moves permanently to
  # the apex, path and query kept, so ranking never splits across two hosts
  # (docs/system/site-pages.md, SEO). Kamal's proxy holds a certificate for both.
  constraints(host: "www.markevans.io") do
    match "(*path)", via: :all, format: false, to: redirect { |_params, request| "https://markevans.io#{request.fullpath}" }
  end

  devise_for :users
  # Health check endpoint for Kamal
  get "up" => "rails/health#show", as: :rails_health_check

  # SEO
  get "sitemap.xml", to: "home#sitemap", as: :sitemap, defaults: { format: "xml" }
  get "robots.txt", to: "robots#show", as: :robots, defaults: { format: "text" }

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
