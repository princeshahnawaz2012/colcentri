Colcentric::Application.routes.draw do

  resources :licence_infos

  resources :licences

  resources :help
  match 'first_section_help' => 'help#first_section', :as => :first_section_help
  match 'first_section_pt_help' => 'help#first_section_pt', :as => :first_section_pt_help
  match 'first_section_en_help' => 'help#first_section_en', :as => :first_section_en_help

  match 'second_section_help' => 'help#second_section', :as => :second_section_help
  match 'second_section_pt_help' => 'help#second_section_pt', :as => :second_section_pt_help
  match 'second_section_en_help' => 'help#second_section_en', :as => :second_section_en_help

  match 'third_section_help' => 'help#third_section', :as => :third_section_help
  match 'third_section_pt_help' => 'help#third_section_pt', :as => :third_section_pt_help
  match 'third_section_en_help' => 'help#third_section_en', :as => :third_section_en_help



  resources :form_options

  resources :forms

  resources :results

  resources :fields

  match '/calendar(/:year(/:month))' => 'calendar#index', :as => :calendar, :constraints => {:year => /\d{4}/, :month => /\d{1,2}/}

	# To be deleted

  #get "drafts_controller/index"

  #get "drafts_controller/show"

  #get "drafts_controller/create"

  #resources :sent

  #resources :mailbox

  #resources :messages


  resources :videoconference_subscriptions

  resources :participants



  get "user_directory/index"

  # If secure_logins is true, constrain matches to ssl requests
  class SSLConstraints
    def self.matches?(request)
      !Colcentric.config.secure_logins || request.ssl?
    end
  end

  resources :sites, :only => [:show, :new, :create]



  match '/public' => 'public/projects#index', :as => :public_projects


  #match '/messages/reply/:id' => 'messages#reply', :as =>:reply_message


  match '/messages/new' => 'messages#new', :as => :new_message

  match '/debugrrrrrrr/:id' => 'mailbox#message_actions', :as =>:show_received_message

  match '/createmessage' => 'sent#create', :as =>:create_message

  match '/debug/:id' => 'drafts#draft_actions'

  match '/resave_draft' => 'sent#save_draft', :as =>:resave_draft

  match '/drafts' => 'drafts#index', :as => :show_drafts
  match '/mailbox' => 'mailbox#index', :as =>:show_inbox
  match '/sent' => 'sent#index', :as =>:show_sent

  match '/messages/:id' => 'messages#show', :as =>:show_received_message
  match '/drafts/:id' => 'drafts#show', :as =>:show_saved_message
  match '/sent/:id' => 'sent#show', :as =>:show_sent_message

  match '/delete_received/:id' => 'mailbox#delete_received', :as => :delete_received
  match '/delete_sent_saved/:id' => 'mailbox#delete_sent_saved', :as => :delete_sent_saved


  namespace :public do
    match ':id' => 'projects#show', :as => :project
    match ':project_id/conversations' => 'conversations#index', :as => :project_conversations
    match ':project_id/conversations/:id' => 'conversations#show', :as => :project_conversation
    match ':project_id/:id' => 'pages#show', :as => :project_page
  end

  match 'api' => 'apidocs#index', :as => :api
  match 'api/concepts' => 'apidocs#concepts', :as => :api_concepts
  match 'api/routes' => 'apidocs#routes', :as => :api_routes
  match 'api/changes' => 'apidocs#changes', :as => :api_changes
  match 'api/:model' => 'apidocs#model', :as => :api_model

  resources :sprockets, :only => [:index, :show]

  #Constrain all requests to the ssl constraint
  scope :constraints => SSLConstraints do

    match '/logout' => 'sessions#destroy', :as => :logout
    match '/login' => 'sessions#new', :as => :login
    match '/login/:username' => 'sessions#backdoor', :as => :login_backdoor if Rails.env.cucumber?

    match '/register' => 'users#create', :as => :register
    match '/signup' => 'users#new', :as => :signup

    match '/search' => 'search#index', :as => :search

    match '/text_styles' => 'users#text_styles', :as => :text_styles
    match '/invite_format' => 'invitations#invite_format', :as => :invite_format
    match '/feeds' => 'users#feeds', :as => :feeds
    match '/calendars' => 'users#calendars', :as => :calendars
    match '/disable_splash' => 'users#disable_splash', :as => :disable_splash
    match '/forgot' => 'reset_passwords#new', :as => :forgot_password
    match '/reset/:reset_code' => 'reset_passwords#reset', :as => :reset_password
    match '/forgetting' => 'reset_passwords#update_after_forgetting', :as => :update_after_forgetting, :method => :put
    match '/reset_password_sent' => 'reset_passwords#sent', :as => :sent_password

    match '/format/:f' => 'sessions#change_format', :as => :change_format

    match '/projects/:project_id/invite/:login' => 'invitations#create', :as => :create_project_invitation, :method => :post
    match '/organizations/:organization_id/invite/:login' => 'invitations#create', :as => :create_organization_invitation, :method => :post
    match '/project_groups/:project_group_id/invite/:login' => 'invitations#create', :as => :create_project_group_invitation, :method => :post

    match '/auth/:provider/callback' => 'auth#callback', :as => :auth_callback
    match '/auth/failure' => 'auth#failure', :as => :auth_failure
    match '/complete_signup' => 'users#complete_signup', :as => :complete_signup
    match '/auth/:provider/unlink' => 'users#unlink_app', :as => :unlink_app
    match '/auth/google' => 'auth#index', :as => :authorize_google_docs, :defaults => {:provider => 'google'}

    resources :google_docs do
      get :search, :on => :collection
    end

    match '/i18n/environment.js' => 'javascripts#environment', :as => :javascript_environment

    #RAILS 3 Useless resource?
    resources :reset_passwords
    resource :session

    resources :organizations do
      member do
        get :projects
        get :external_view
        get :delete
        get :appearance
      end

      resources :invitations do
        member do
          put :accept
          put :decline
          get :resend
        end
      end

      match 'invite_people' => 'organizations#invite_people', :as => :invite_people, :via => :get
      match 'invite_people' => 'organizations#send_invites', :as => :send_invites, :via => :post

      resources :memberships do
        member do
          get :change_role
          get :add
          get :remove
        end
      end
    end

    # REPORTS
    resources :reports

    match '/report/user' => 'reports#show', :as => :report_user, :sub_action => 'user_reports'

    match '/terms' => 'users#show', :as => :terms, :sub_action => 'terms'

    match '/account/settings' => 'users#edit', :as => :account_settings, :sub_action => 'settings'
    match '/account/picture' => 'users#edit', :as => :account_picture, :sub_action => 'picture'
    match '/account/profile' => 'users#edit', :as => :account_profile, :sub_action => 'profile'
    match '/account/linked_accounts' => 'users#edit', :as => :account_linked_accounts, :sub_action => 'linked_accounts'
    match '/account/notifications' => 'users#edit', :as => :account_notifications, :sub_action => 'notifications'
    match '/account/delete' => 'users#edit', :as => :account_delete, :sub_action => 'delete'
    match '/account/destroy' => 'users#destroy', :as => :destroy_user
    match '/account/activity_feed_mode/collapsed' => 'users#change_activities_mode', :as => :collapse_activities, :collapsed => true
    match '/account/activity_feed_mode/expanded' => 'users#change_activities_mode', :as => :expand_activities, :collapsed => false

    resources :colcentric_datas, :path => '/datas'

    match 'update_role_people' => 'people#update_role', :as => :update_role_people
    match 'edit_role_people' => 'people#edit_role', :as => :edit_role_people

    resource :invoices
    match 'index_invoice' => 'invoices#index', :as => :index_invoice
    match 'show_invoice' => 'invoices#show', :as => :show_invoice



    resource :forms
    match 'index_form' => 'forms#index', :as => :index_forms
    match 'new_form' => 'forms#new', :as => :new_forms
    match 'edit_form' => 'forms#edit', :as => :edit_forms
    match 'delete_form' => 'forms#destroy', :as => :delete_form
    match 'new_form_form' => 'forms#new_form', :as => :new_form_forms
    match 'answer_form' => 'forms#answer', :as => :answer_form
    match 'get_answers_form' => 'forms#get_answers', :as => :get_answers_forms
    match 'show_answers_form' => 'forms#show_answers', :as => :show_answers_form
    match 'list_answers_form' => 'forms#list_answers', :as => :list_answers_form
    match 'delete_answers_form' => 'forms#delete_answers', :as => :delete_answers_form
    match 'delete_field' => 'fields#destroy', :as => :delete_field
    match 'edit_fields_form' => 'fields#edit_fields', :as => :edit_fields_form
    match 'update_fields_form' => 'fields#update_fields', :as => :update_fields_form
    match 'publish_form' => 'forms#publish', :as => :publish_form
    match 'close_form' => 'forms#close', :as => :close_form



    resource :videoconferences
    match 'show_records_videoconference' => 'videoconferences#show_records', :as => :show_records_videoconference
    match 'delete_videoconference' => 'videoconferences#delete', :as => :delete_videoconference
    match 'error_videoconference' => 'videoconferences#error', :as => :error_videoconference
    match 'index_videoconference' => 'videoconferences#index', :as => :index_videoconference
    match 'edit_videoconference' => 'videoconferences#edit', :as => :edit_videoconference
    match 'new_videoconference' => 'videoconferences#new', :as => :new_videoconference
    match 'show_videoconference' => 'videoconferences#show', :as => :show_videoconference
    match 'new_room_videoconference' => 'videoconferences#new_room', :as => :new_room_videoconference
    match 'edit_room_videoconference' => 'videoconferences#edit_room', :as => :edit_room_videoconference
    match 'start_videoconference_path' => 'videoconferences#start', :as => :start_videoconference
    match 'delete_participant_videoconference' => 'videoconferences#delete_participant', :as => :delete_participant_videoconference
    resources :users do
      resources :invitations
      member do
        get :confirm_email
        get :unconfirmed_email
        get :payment_needed
        get :contact_importer
      end
      resources :conversations

      resources :task_lists do
        resources :tasks
      end

      match 'activities/users/:id/show_more(.:format)' => 'activities#show_more', :as => :show_more, :method => :get

    end

    match 'subscriptions/ipn', :controller => "subscriptions", :action => "ipn", :method => :put
    match 'subscriptions/error' => 'subscriptions#error', :as => :error_subscription
    resources :subscriptions do
      member do
        post :set_checkout
        get :get_details
        get :show_details
        post :create_recurring
        get :pending
        get :thanks
        get :error
        get :cancel
        get :suspend
        get :reactivate
        get :unassign_sponsor
      end
      collection do
        get :buy
        get :create_sponsors
        post :assign_sponsors
      end
    end


  #  match 'shopping_cart' => 'shopping_carts#refresh', :as => :refresh_shopping_cart
    match 'shopping_cart' => 'shopping_carts#buy', :as => :buy_shopping_cart
    match 'shopping_cart' => 'shopping_carts#update_total', :as => :update_total_shopping_cart
    resources :shopping_carts, :path => 'shopping' do
      member do
        post :save
        get :check_taxes
        post :set_checkout
        get :get_details
        get :show_details
        post :create_recurring
        get :thanks
        get :error
      end
      collection do
        get :buy
      end
    end

    match 'activities(.:format)' => 'activities#show', :as => :activities, :method => :get
    match 'activities/:id/show_new(.:format)' => 'activities#show_new', :as => :show_new, :method => :get
    match 'activities/:id/show_more(.:format)' => 'activities#show_more', :as => :show_more, :method => :get
    match 'activities/:id/show_thread(.:format)' => 'activities#show_thread', :as => :show_thread, :method => :get

    match 'projects/archived.:format' => 'projects#index', :as => :project_archived, :sub_action => 'archived'

    match 'hooks/:hook_name' => 'hooks#create', :as => :hooks, :via => :post


    match 'projects/:project_id/tasks/:id/reorder' => 'tasks#reorder', :as => :reorder, :method => :put

    resources :projects do
      member do
        post :accept
        post :decline
        put :transfer
        get :join
      end

      match 'time/:year/:month' => 'hours#index', :as => :hours_by_month, :via => :get
      match 'time/by_period' => 'hours#by_period', :as => :hours_by_period, :via => :get
      match 'time' => 'hours#index', :as => :time
      match 'settings' => 'projects#edit', :as => :settings, :sub_action => 'settings'
      match 'picture' => 'projects#edit', :as => :picture, :sub_action => 'picture'
      match 'deletion' => 'projects#edit', :as => :deletion, :sub_action => 'deletion'
      match 'ownership' => 'projects#edit', :as => :ownership, :sub_action => 'ownership'
      match 'advanced' => 'projects#edit', :as => :advanced, :sub_action => 'advanced'

      resources :invitations do
        member do
          put :accept
          put :decline
          get :resend
        end
      end

      match 'activities(.:format)' => 'activities#show', :as => :activities, :method => :get
      match 'activities/:id/show_new(.:format)' => 'activities#show_new', :as => :show_new, :method => :get
      match 'activities/:id/show_more(.:format)' => 'activities#show_more', :as => :show_more, :method => :get
      resources :uploads
      match 'hooks/:hook_name' => 'hooks#create', :as => :hooks, :via => :post

      match 'invite_people' => 'projects#invite_people', :as => :invite_people, :via => :get
      match 'invite_people' => 'projects#send_invites', :as => :send_invites, :via => :post

      ##match 'projects/prueba1/tasks/16/reorder' => 'videoconferences#index', :as => 'projects/prueba1/tasks/16/reorder', :method => :put

      resources :tasks do
        member do
          put :reorder
          put :watch
          put :unwatch
        end

        resources :comments
      end

      resources :task_lists do
        collection do
          get :gantt_view
          get :archived
          put :reorder
        end
        member do
          put :archive
          put :unarchive
          put :watch
          put :unwatch
        end

        resources :tasks do
          member do
            put :watch
            put :unwatch
          end

          resources :comments
        end
      end

      match 'contacts' => 'people#contacts', :as => :contacts, :method => :get

      resources :people do
        collection do
          get :list
        end
        member do
          get :destroy
        end
      end

      resources :conversations do
        member do
          put :convert_to_task
          put :watch
          put :unwatch
        end

        resources :comments
      end

      resources :pages do
        collection do
          post :resort
        end
        member do
          post :reorder
        end
        # In rails 2, we have :pages, :has_many => :task_list ?!
        resources :notes,:dividers,:uploads
      end

      match 'search' => 'search#index', :as => :search

      resources :google_docs do
        collection do
          :search
        end
      end


    end

    resources :project_groups do
      member do
        post :accept
        post :decline
        put :transfer
        get :join
      end

      match 'new' => 'project_groups#new'
      match 'settings' => 'project_groups#edit', :as => :settings, :sub_action => 'settings'
      match 'deletion' => 'project_groups#edit', :as => :deletion, :sub_action => 'deletion'
      match 'ownership' => 'project_groups#edit', :as => :ownership, :sub_action => 'ownership'
      match 'advanced' => 'project_groups#edit', :as => :advanced, :sub_action => 'advanced'

      resources :invitations do
        member do
          put :accept
          put :decline
          get :resend
        end
      end

      match 'invite_people' => 'project_groups#invite_people', :as => :invite_people, :via => :get
      match 'invite_people' => 'project_groups#send_invites', :as => :send_invites, :via => :post

      match 'contacts' => 'project_group_roles#contacts', :as => :contacts, :method => :get

      resources :project_group_roles do
        member do
          get :destroy
        end
      end
    end

    namespace :api_v1, :path => 'api/1' do
      resources :projects, :except => [:new, :edit] do
        member do
          put :transfer
        end

        resources :activities, :only => [:index, :show]

        resources :people, :except => [:create, :new, :edit]

        resources :comments, :except => [:new, :create, :edit]

        resources :conversations, :except => [:new, :edit] do
          member do
            put :watch
            put :unwatch
            post :convert_to_task
          end

          resources :comments, :except => [:new, :edit]
        end

        resources :invitations, :except => [:new, :edit, :update] do
          member do
            put :resend
          end
        end

        resources :task_lists, :except => [:new, :edit] do
          member do
            put :archive
            put :unarchive
          end

          resources :tasks, :except => [:new, :edit]
        end

        resources :tasks, :except => [:new, :edit, :create] do
          member do
            put :watch
            put :unwatch
          end

          resources :comments, :except => [:new, :edit]
        end

        resources :uploads, :except => [:new, :edit, :update]

        resources :pages, :except => [:new, :edit] do
          collection do
            put :resort
          end

          member do
            put :reorder
          end
        end

        resources :notes, :except => [:new, :edit]

        resources :dividers, :except => [:new, :edit]

        match 'search' => 'search#index', :as => :search
      end

      resources :activities, :only => [:index, :show]

      resources :invitations, :except => [:new, :edit, :update, :create] do
        member do
          put :accept
        end
      end

      resources :users, :only => [:index, :show]

      resources :tasks, :except => [:new, :edit, :create] do
        member do
          put :watch
          put :unwatch
        end
      end

      resources :comments, :except => [:new, :create, :edit]

      resources :conversations, :except => [:new, :edit] do
        member do
          put :watch
          put :unwatch
        end

        resources :comments, :except => [:new, :edit]
      end

      resources :task_lists, :except => [:new, :edit] do
        resources :tasks, :except => [:new, :edit]
      end

      resources :tasks, :except => [:new, :edit, :create] do
        member do
          put :watch
          put :unwatch
        end

        resources :comments, :except => [:new, :edit]
      end

      resources :uploads, :except => [:new, :edit, :update]
      resources :pages, :except => [:new, :edit] do
        collection do
          put :resort
        end
        member do
          put :reorder
        end
      end

      resources :notes, :except => [:new, :edit]

      resources :dividers, :except => [:new, :edit]

      resources :organizations, :except => [:new, :edit, :destroy] do
        resources :projects, :except => [:new, :edit] do
          member do
            put :transfer
          end
        end

        resources :memberships, :except => [:new, :edit, :create]
      end
      match 'search' => 'search#index', :as => :search
      match 'account' => 'users#current', :as => :account, :via => :get
    end

    resources :task_lists, :only => [ :index ] do
      collection do
        get :gantt_view
      end
    end

    resources :conversations, :only => [ :create ]

    match 'time/:year/:month' => 'hours#index', :as => :hours_by_month, :via => :get
    match 'time/by_period' => 'hours#by_period', :as => :hours_by_period, :via => :get
    match 'time' => 'hours#index', :as => :time

    match '/my_projects' => 'projects#list', :as => :all_projects

    match 'assets/:id/:style/:filename' => 'uploads#download', :constraints => { :filename => /.*/ }, :via => :get


    match 'create_user_files' => 'user_files#create', :as => :create_user_files
    match 'delete_user_files' => 'user_files#delete', :as => :delete_user_files
    match 'new_user_files' => 'user_files#new', :as => :new_user_files
    match 'changeDirectory_user_files' => 'user_files#changeDirectory', :as => :changeDirectory_user_files
    match 'moveFile_user_files' => 'user_files#moveFile', :as => :moveFile_user_files
    match 'rename_user_files' => 'user_files#rename', :as => :rename_user_files
    match 'change_name_user_files' => 'user_files#change_name', :as => :change_name_user_files
    match 'search_user_files' => 'user_files#search', :as => :search_user_files
    match 'searchResults_user_files' => 'user_files#searchResults', :as => :searchResults_user_files
    resources :user_files

    match 'new_user_directory' => 'user_directories#new', :as => :new_user_directory
    match 'create_user_directory' => 'user_directories#create', :as => :create_user_directory
    match 'delete_user_directory' => 'user_directories#delete', :as => :delete_user_directory
    match 'rename_user_directory' => 'user_directories#rename', :as => :rename_user_directory
    match 'change_name_user_directory' => 'user_directories#change_name', :as => :change_name_user_directory
    match 'show_content_user_directory' => 'user_directories#show_content', :as => :show_content_user_directory
    match 'changeDirectory_user_directory' => 'user_directories#changeDirectory', :as => :changeDirectory_user_directory
    match 'moveDirectory_user_directory' => 'user_directories#moveDirectory', :as => :moveDirectory_user_directory
    resources :user_directories
    match "admin/updateLicence" => "admin#updateLicence", :via => :post
    match 'usersManagement_admin' => 'admin#usersManagement', :as => :usersManagement_admin
    match 'invoicesManagement_admin' => 'admin#invoicesManagement', :as => :invoicesManagement_admin
    match 'licencesManagement_admin' => 'admin#licencesManagement', :as => :licencesManagement_admin
    match 'subscriptionsManagement_admin' => 'admin#subscriptionsManagement', :as => :subscriptionsManagement_admin
    match 'showUser_admin' => 'admin#showUser', :as => :showUser_admin
    match 'deleteUser_admin' => 'admin#deleteUser', :as => :deleteUser_admin
    match 'showInvoice_admin' => 'admin#showInvoice', :as => :showInvoice_admin
    match 'deleteInvoice_admin' => 'admin#deleteInvoice', :as => :deleteInvoice_admin
    match 'showSubscription_admin' => 'admin#showSubscription', :as => :showSubscription_admin
    match 'deleteSubscription_admin' => 'admin#deleteSubscription', :as => :deleteSubscription_admin
    match 'editSubscription_admin' => 'admin#editSubscription', :as => :editSubscription_admin
    match 'updateSubscription_admin' => 'admin#updateSubscription', :as => :updateSubscription_admin
    match 'deleteLicence_admin' => 'admin#deleteLicence', :as => :deleteLicence_admin
    match 'showLicence_admin' => 'admin#showLicence', :as => :showLicence_admin
    match 'newLicence_admin' => 'licences#newLicence', :as => :newLicence_admin
    #match 'editLicence_admin' => 'admin#updateLicence', :as => :editLicence_admin
    match 'statistics_admin' => 'admin#statistics', :as => :statistics_admin
    match 'updateUsedStorage_admin' => 'admin#updateUsedStorage', :as => :updateUsedStorage_admin
    match 'updateCalendarEvents_admin' => 'admin#updateCalendarEvents', :as => :updateCalendarEvents_admin
    match 'transform_new_tasks_into_opened_admin' => 'admin#transform_new_tasks_into_opened', :as => :transform_new_tasks_into_opened_admin
    match 'update_tasks_priority_admin' => 'admin#update_tasks_priority' , :as => :update_tasks_priority_admin
    match 'admin' => 'admin#index', :as => :admin
    resources :admin

    match 'rename_uploads' => 'uploads#rename', :as => :rename_uploads
    match 'change_name_uploads' => 'uploads#change_name', :as => :change_name_uploads
    match 'changeDirectory_uploads' => 'uploads#changeDirectory', :as => :changeDirectory_uploads
    match 'moveFile_uploads' => 'uploads#moveFile', :as => :moveFile_uploads
    match 'delete_uploads' => 'uploads#delete', :as => :delete_uploads
    match 'new_upload' => 'uploads#new', :as => :new_upload
    match 'create_upload' => 'uploads#create', :as => :create_upload
    match 'search_uploads' => 'uploads#search', :as => :search_uploads
    match 'searchResults_uploads' => 'uploads#searchResults', :as => :searchResults_uploads

    match 'new_upload_directory' => 'upload_directories#new', :as => :new_upload_directory
    match 'create_upload_directory' => 'upload_directories#create', :as => :create_upload_directory
    match 'show_content_upload_directory' => 'upload_directories#show_content', :as => :show_content_upload_directory
    match 'rename_upload_directory' => 'upload_directories#rename', :as => :rename_upload_directory
    match 'changeDirectory_upload_directory' => 'upload_directories#changeDirectory', :as => :changeDirectory_upload_directory
    match 'delete_upload_directory' => 'upload_directories#delete', :as => :delete_upload_directory
    match 'changeName_upload_directory' => 'upload_directories#changeName', :as => :changeName_upload_directory
    match 'moveDirectory_upload_directory' => 'upload_directories#moveDirectory', :as => :moveDirectory_upload_directory
    resources :upload_directories

    match 'new_calendar_entry' => 'calendar_entries#new', :as => :new_calendar_entry
    match 'create_calendar_entry' => 'calendar_entries#create', :as => :create_calendar_entry
    match 'show_calendar_entry' => 'calendar_entries#show', :as => :show_calendar_entry
    match 'delete_calendar_entry' => 'calendar_entries#delete', :as => :delete_calendar_entry
    match 'edit_calendar_entry' => 'calendar_entries#edit', :as => :edit_calendar_entry
    match 'update_calendar_entry' => 'calendar_entries#update', :as => :update_calendar_entry

    match 'collaboration_calendar' => 'calendar#collaboration_calendar', :as => :collaboration_calendar
    match 'project_calendar' => 'calendar#project_calendar', :as => :project_calendar

    match 'my_tasks' => 'task_lists#my_tasks', :as => :my_tasks

    match 'show_all_project_groups' => 'project_groups#show_all', :as => :show_all_project_groups
    match 'update_name_project_group' => 'project_groups#update_name', :as => :update_name_project_group
    match 'settings_project_group' => 'project_groups#settings', :as => :settings_project_group

    match 'upload_file_page' => 'pages#upload_file', :as => :upload_file_page

    match 'show_filtered_task_list' => 'task_lists#show_filtered', :as => :show_filtered_task_list

    match 'show_page' => 'pages#show', :as => :show_page
  end

  root :to => 'projects#index'

  if Rails.env.development?
    mount Emailer::Preview => 'mail_view'
  end

end
