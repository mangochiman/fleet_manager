Rails.application.routes.draw do
  devise_for :users
  
  # Root path - redirect to dashboard after login
  root to: "dashboard#index"
  
  # Dashboard
  get "dashboard", to: "dashboard#index"
  
  # Resources
  resources :sales do
    member do
      get :mark_paid_form
      patch :mark_paid
      patch :mark_banked
      get :proof
      get :record_payment_form
      patch :record_payment
    end
  end
  
  resources :expenses
  resources :vehicles
  resources :products do
    member do
      patch :toggle_status
    end
  end
  
  # Reports
  get "reports", to: "reports#index"
  get "reports/sales", to: "reports#sales_report"
  get "reports/expenses", to: "reports#expense_report"
  get "reports/profit_loss", to: "reports#profit_loss_report"
  get "reports/outstanding", to: "reports#outstanding_report"
  
  # Exports
  get "exports/sales", to: "exports#sales"
  get "exports/expenses", to: "exports#expenses"
  get "exports/outstanding", to: "exports#outstanding"
end