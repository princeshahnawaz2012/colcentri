# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2011200810122000) do

  create_table "activities", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.integer  "target_id"
    t.string   "target_type"
    t.string   "action"
    t.string   "comment_target_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "comment_target_id"
    t.boolean  "deleted",             :default => false, :null => false
  end

  add_index "activities", ["created_at"], :name => "index_activities_on_created_at"
  add_index "activities", ["deleted"], :name => "index_activities_on_deleted"
  add_index "activities", ["project_id"], :name => "index_activities_on_project_id"
  add_index "activities", ["target_id"], :name => "index_activities_on_target_id"
  add_index "activities", ["target_type"], :name => "index_activities_on_target_type"

  create_table "addresses", :force => true do |t|
    t.integer "card_id"
    t.string  "street"
    t.string  "city"
    t.string  "state"
    t.string  "zip"
    t.string  "country"
    t.integer "account_type", :default => 0
  end

  create_table "announcements", :force => true do |t|
    t.integer "user_id"
    t.integer "comment_id"
  end

  create_table "app_links", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "app_user_id"
    t.text     "custom_attributes"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "access_token"
    t.string   "access_secret"
  end

  add_index "app_links", ["user_id"], :name => "index_app_links_on_user_id"

  create_table "calendar_entries", :force => true do |t|
    t.string   "title"
    t.string   "description"
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cards", :force => true do |t|
    t.integer "user_id"
    t.boolean "public",  :default => false
  end

  create_table "colcentric_datas", :force => true do |t|
    t.integer  "user_id"
    t.integer  "type_id"
    t.text     "project_ids"
    t.text     "map_data"
    t.string   "processed_data_file_name"
    t.string   "processed_data_content_type"
    t.integer  "processed_data_file_size"
    t.datetime "processed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "processed_objects"
    t.string   "service"
    t.integer  "status",                      :default => 0
    t.boolean  "deleted",                     :default => false, :null => false
  end

  add_index "colcentric_datas", ["deleted"], :name => "index_colcentric_datas_on_deleted"

  create_table "comments", :force => true do |t|
    t.integer  "target_id"
    t.string   "target_type"
    t.integer  "project_id"
    t.integer  "user_id"
    t.text     "body"
    t.text     "body_html"
    t.float    "hours"
    t.boolean  "billable"
    t.integer  "status"
    t.integer  "previous_status"
    t.integer  "assigned_id"
    t.integer  "previous_assigned_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "due_on"
    t.date     "previous_due_on"
    t.integer  "uploads_count",              :default => 0
    t.boolean  "deleted",                    :default => false, :null => false
    t.integer  "priority"
    t.integer  "previous_priority"
    t.date     "start_date"
    t.date     "previous_start_date"
    t.string   "task_participants"
    t.string   "previous_task_participants"
  end

  add_index "comments", ["created_at"], :name => "index_comments_on_created_at"
  add_index "comments", ["deleted"], :name => "index_comments_on_deleted"
  add_index "comments", ["hours"], :name => "index_comments_on_hours"
  add_index "comments", ["project_id"], :name => "index_comments_on_project_id"
  add_index "comments", ["target_type", "target_id", "user_id"], :name => "index_comments_on_target_type_and_target_id_and_user_id"

  create_table "comments_read", :force => true do |t|
    t.integer "target_id"
    t.string  "target_type"
    t.integer "user_id"
    t.integer "last_read_comment_id"
  end

  add_index "comments_read", ["target_type", "target_id", "user_id"], :name => "index_comments_read_on_target_type_and_target_id_and_user_id"

  create_table "conversations", :force => true do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.string   "name"
    t.integer  "last_comment_id"
    t.integer  "comments_count",  :default => 0,     :null => false
    t.text     "watchers_ids"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "simple",          :default => false
    t.boolean  "deleted",         :default => false, :null => false
  end

  add_index "conversations", ["deleted"], :name => "index_conversations_on_deleted"
  add_index "conversations", ["project_id"], :name => "index_conversations_on_project_id"

  create_table "dividers", :force => true do |t|
    t.integer  "page_id"
    t.integer  "project_id"
    t.string   "name"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",    :default => false, :null => false
  end

  add_index "dividers", ["deleted"], :name => "index_dividers_on_deleted"
  add_index "dividers", ["page_id"], :name => "index_dividers_on_page_id"

  create_table "draft_copies", :force => true do |t|
    t.integer  "draft_recipient_id"
    t.integer  "message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "email_addresses", :force => true do |t|
    t.integer "card_id"
    t.string  "name"
    t.integer "account_type", :default => 0
  end

  create_table "email_bounces", :force => true do |t|
    t.string   "email"
    t.string   "exception_type"
    t.string   "exception_message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "email_bounces", ["created_at"], :name => "index_email_bounces_on_created_at"
  add_index "email_bounces", ["email"], :name => "index_email_bounces_on_email"

  create_table "emails", :force => true do |t|
    t.string   "from"
    t.string   "to"
    t.integer  "last_send_attempt", :default => 0
    t.text     "mail"
    t.datetime "created_on"
  end

  create_table "events", :force => true do |t|
    t.string   "name"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer  "task_id"
    t.integer  "calendar_entry_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "fields", :force => true do |t|
    t.integer  "form_id"
    t.string   "name"
    t.integer  "field_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "form_options", :force => true do |t|
    t.integer  "field_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forms", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.string   "title"
    t.string   "description"
    t.boolean  "multiple"
    t.boolean  "publish"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "google_docs", :force => true do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.integer  "comment_id"
    t.string   "title"
    t.string   "document_id"
    t.string   "document_type"
    t.string   "url"
    t.string   "edit_url"
    t.string   "acl_url"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",       :default => false, :null => false
  end

  add_index "google_docs", ["comment_id"], :name => "index_google_docs_on_comment_id"
  add_index "google_docs", ["deleted"], :name => "index_google_docs_on_deleted"
  add_index "google_docs", ["project_id"], :name => "index_google_docs_on_project_id"
  add_index "google_docs", ["user_id"], :name => "index_google_docs_on_user_id"

  create_table "ims", :force => true do |t|
    t.integer "card_id"
    t.string  "name"
    t.integer "account_im_type", :default => 0
    t.integer "account_type",    :default => 0
  end

  create_table "invitations", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.integer  "role",             :default => 2
    t.string   "email"
    t.integer  "invited_user_id"
    t.string   "token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "membership",       :default => 10
    t.boolean  "deleted",          :default => false, :null => false
    t.integer  "organization_id"
    t.integer  "project_group_id"
    t.integer  "subscription_id"
  end

  add_index "invitations", ["deleted"], :name => "index_invitations_on_deleted"
  add_index "invitations", ["organization_id"], :name => "index_invitations_on_organization_id"
  add_index "invitations", ["project_id"], :name => "index_invitations_on_project_id"
  add_index "invitations", ["user_id"], :name => "index_invitations_on_user_id"

  create_table "invoices", :force => true do |t|
    t.integer  "user_id"
    t.integer  "shopping_cart_id"
    t.string   "invoice_number"
    t.integer  "status"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "organization"
    t.string   "phone"
    t.string   "email"
    t.string   "country"
    t.string   "address"
    t.string   "city"
    t.string   "postal_code"
    t.integer  "n_monthly_licenses"
    t.integer  "n_biannual_licenses"
    t.integer  "n_annual_licenses"
    t.integer  "n_videoconferences"
    t.integer  "n_storage"
    t.float    "ammount"
    t.string   "iva"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "promotional_code"
    t.integer  "invoice_type"
    t.boolean  "apply_iva"
  end

  create_table "licences", :force => true do |t|
    t.string   "name",         :limit => 100
    t.string   "licence_type", :limit => 100
    t.integer  "period",                      :null => false
    t.integer  "amount"
    t.integer  "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  create_table "memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "organization_id"
    t.integer  "role",            :default => 20
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "message_copies", :force => true do |t|
    t.integer  "recipient_id"
    t.integer  "message_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "read"
    t.boolean  "deleted"
  end

  create_table "messages", :force => true do |t|
    t.integer  "user_id"
    t.integer  "recipient"
    t.time     "time"
    t.date     "date"
    t.string   "subject"
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "conv_id"
    t.boolean  "sent"
  end

  create_table "notes", :force => true do |t|
    t.integer  "page_id"
    t.integer  "project_id"
    t.string   "name"
    t.text     "body"
    t.text     "body_html"
    t.integer  "position"
    t.integer  "last_comment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",         :default => false, :null => false
  end

  add_index "notes", ["deleted"], :name => "index_notes_on_deleted"
  add_index "notes", ["page_id"], :name => "index_notes_on_page_id"

  create_table "organizations", :force => true do |t|
    t.string   "name"
    t.string   "permalink",                                                   :null => false
    t.string   "language",          :default => "en"
    t.string   "time_zone",         :default => "Eastern Time (US & Canada)"
    t.string   "domain"
    t.text     "description"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "settings"
    t.boolean  "deleted",           :default => false,                        :null => false
  end

  add_index "organizations", ["deleted"], :name => "index_organizations_on_deleted"
  add_index "organizations", ["domain"], :name => "index_organizations_on_domain"
  add_index "organizations", ["permalink"], :name => "index_organizations_on_permalink"

  create_table "page_slots", :force => true do |t|
    t.integer "page_id"
    t.integer "rel_object_id",                 :default => 0, :null => false
    t.string  "rel_object_type", :limit => 30
    t.integer "position",                      :default => 0, :null => false
  end

  create_table "pages", :force => true do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.string   "name"
    t.text     "description"
    t.integer  "last_comment_id"
    t.text     "watchers_ids"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.string   "permalink"
    t.boolean  "deleted",         :default => false, :null => false
  end

  add_index "pages", ["deleted"], :name => "index_pages_on_deleted"
  add_index "pages", ["project_id"], :name => "index_pages_on_project_id"

  create_table "participants", :force => true do |t|
    t.integer  "videoconference_id"
    t.integer  "role"
    t.string   "login_or_email"
    t.boolean  "invitation_email"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "people", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.integer  "source_user_id"
    t.string   "permissions"
    t.integer  "role",           :default => 2
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",        :default => false, :null => false
  end

  add_index "people", ["deleted"], :name => "index_people_on_deleted"
  add_index "people", ["project_id"], :name => "index_people_on_project_id"
  add_index "people", ["user_id", "project_id"], :name => "index_people_on_user_id_and_project_id", :unique => true
  add_index "people", ["user_id"], :name => "index_people_on_user_id"

  create_table "phone_numbers", :force => true do |t|
    t.integer "card_id"
    t.string  "name"
    t.integer "account_type", :default => 0
  end

  create_table "project_group_roles", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_group_id"
    t.integer  "role",             :default => 20
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_groups", :force => true do |t|
    t.string   "name"
    t.string   "permalink"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
    t.integer  "user_id"
  end

  create_table "projects", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "permalink"
    t.integer  "last_comment_id"
    t.integer  "comments_count",   :default => 0,     :null => false
    t.boolean  "archived",         :default => false
    t.boolean  "tracks_time",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "public"
    t.integer  "organization_id"
    t.boolean  "deleted",          :default => false, :null => false
    t.integer  "project_group_id"
    t.integer  "personalization",  :default => 0
  end

  add_index "projects", ["deleted"], :name => "index_projects_on_deleted"
  add_index "projects", ["permalink"], :name => "index_projects_on_permalink"

  create_table "recordings", :force => true do |t|
    t.integer  "videoconference_id"
    t.string   "room_id"
    t.string   "record_id"
    t.boolean  "anonymous_playback"
    t.string   "title"
    t.string   "description"
    t.string   "password"
    t.integer  "duration"
    t.string   "recording_link"
    t.datetime "creation_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reports", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "reset_passwords", :force => true do |t|
    t.integer  "user_id"
    t.string   "reset_code"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "results", :force => true do |t|
    t.integer  "field_id"
    t.integer  "user_id"
    t.integer  "result"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :default => "", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "shopping_carts", :force => true do |t|
    t.string   "promotional_code"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "ammount"
  end

  create_table "social_networks", :force => true do |t|
    t.integer "card_id"
    t.string  "name"
    t.integer "account_network_type", :default => 0
    t.integer "account_type",         :default => 0
  end

  create_table "subscriptions", :force => true do |t|
    t.integer  "status"
    t.integer  "licence_type"
    t.integer  "user_id"
    t.integer  "sponsor_user_id"
    t.string   "paypal_profileid"
    t.string   "paypal_profilestatus"
    t.string   "paypal_correlationid"
    t.datetime "last_payment_date"
    t.datetime "expiration_date"
    t.boolean  "deleted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "trial_expiration_date"
    t.integer  "shopping_cart_id"
  end

  create_table "task_lists", :force => true do |t|
    t.integer  "project_id"
    t.integer  "user_id"
    t.integer  "page_id"
    t.string   "name"
    t.integer  "position"
    t.integer  "last_comment_id"
    t.integer  "comments_count",       :default => 0,     :null => false
    t.text     "watchers_ids"
    t.boolean  "archived",             :default => false
    t.integer  "archived_tasks_count", :default => 0,     :null => false
    t.integer  "tasks_count",          :default => 0,     :null => false
    t.datetime "completed_at"
    t.date     "start_on"
    t.date     "finish_on"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",              :default => false, :null => false
  end

  add_index "task_lists", ["deleted"], :name => "index_task_lists_on_deleted"
  add_index "task_lists", ["project_id"], :name => "index_task_lists_on_project_id"

  create_table "task_participants", :force => true do |t|
    t.integer  "task_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tasks", :force => true do |t|
    t.integer  "project_id"
    t.integer  "page_id"
    t.integer  "task_list_id"
    t.integer  "user_id"
    t.string   "name"
    t.integer  "position"
    t.integer  "comments_count",    :default => 0,     :null => false
    t.integer  "last_comment_id"
    t.text     "watchers_ids"
    t.integer  "assigned_id"
    t.integer  "status",            :default => 0
    t.date     "due_on"
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",           :default => false, :null => false
    t.boolean  "private"
    t.integer  "priority"
    t.date     "start_date"
    t.string   "task_participants"
  end

  add_index "tasks", ["deleted"], :name => "index_tasks_on_deleted"
  add_index "tasks", ["project_id"], :name => "index_tasks_on_project_id"
  add_index "tasks", ["task_list_id"], :name => "index_tasks_on_task_list_id"

  create_table "teambox_datas", :force => true do |t|
    t.integer  "user_id"
    t.integer  "type_id"
    t.text     "project_ids"
    t.text     "map_data"
    t.string   "processed_data_file_name"
    t.string   "processed_data_content_type"
    t.integer  "processed_data_file_size"
    t.datetime "processed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "processed_objects"
    t.string   "service"
    t.integer  "status",                      :default => 0
    t.datetime "deleted_at"
    t.boolean  "deleted"
  end

  add_index "teambox_datas", ["deleted"], :name => "index_teambox_datas_on_deleted"

  create_table "upload_directories", :force => true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "user_id"
    t.integer  "upload_directory_id"
    t.integer  "size"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "uploads", :force => true do |t|
    t.integer  "user_id"
    t.integer  "project_id"
    t.integer  "comment_id"
    t.integer  "page_id"
    t.text     "description"
    t.string   "asset_file_name"
    t.string   "asset_content_type"
    t.integer  "asset_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "deleted",             :default => false, :null => false
    t.integer  "upload_directory_id"
    t.string   "amazon_id"
  end

  add_index "uploads", ["comment_id"], :name => "index_uploads_on_comment_id"
  add_index "uploads", ["deleted"], :name => "index_uploads_on_deleted"
  add_index "uploads", ["page_id"], :name => "index_uploads_on_page_id"

  create_table "user_directories", :force => true do |t|
    t.string   "name"
    t.integer  "user_id"
    t.integer  "user_directory_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "size",              :default => 0
  end

  create_table "user_files", :force => true do |t|
    t.integer  "user_id"
    t.integer  "user_directory_id"
    t.integer  "asset_file_size"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "amazon_id"
    t.string   "asset_file_name"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "first_name",                :limit => 20,  :default => ""
    t.string   "last_name",                 :limit => 20,  :default => ""
    t.text     "biography"
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "time_zone",                                :default => "Eastern Time (US & Canada)"
    t.string   "locale",                                   :default => "es"
    t.string   "first_day_of_week",                        :default => "monday"
    t.integer  "invitations_count",                        :default => 0,                            :null => false
    t.string   "login_token",               :limit => 40
    t.datetime "login_token_expires_at"
    t.boolean  "confirmed_user",                           :default => false
    t.string   "rss_token",                 :limit => 40
    t.boolean  "admin",                                    :default => false
    t.integer  "comments_count",                           :default => 0,                            :null => false
    t.boolean  "notify_mentions",                          :default => true
    t.boolean  "notify_conversations",                     :default => true
    t.boolean  "notify_tasks",                             :default => true
    t.string   "avatar_file_name"
    t.string   "avatar_content_type"
    t.integer  "avatar_file_size"
    t.integer  "invited_by_id"
    t.integer  "invited_count",                            :default => 0,                            :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "wants_task_reminder",                      :default => false
    t.text     "recent_projects_ids"
    t.string   "feature_level",                            :default => ""
    t.string   "spreedly_token",                           :default => ""
    t.datetime "avatar_updated_at"
    t.datetime "visited_at"
    t.boolean  "betatester",                               :default => false
    t.boolean  "splash_screen",                            :default => false
    t.integer  "assigned_tasks_count"
    t.integer  "completed_tasks_count"
    t.boolean  "deleted",                                  :default => false,                        :null => false
    t.text     "settings"
    t.string   "company_name"
    t.string   "country"
    t.string   "phone"
    t.string   "comercial_code"
    t.boolean  "terms_of_use"
    t.integer  "used_storage",                             :default => 0
  end

  add_index "users", ["deleted"], :name => "index_users_on_deleted"
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

  create_table "versions", :force => true do |t|
    t.integer  "versioned_id"
    t.string   "versioned_type"
    t.integer  "user_id"
    t.string   "user_type"
    t.string   "user_name"
    t.text     "modifications"
    t.integer  "number"
    t.string   "tag"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "versions", ["created_at"], :name => "index_versions_on_created_at"
  add_index "versions", ["number"], :name => "index_versions_on_number"
  add_index "versions", ["tag"], :name => "index_versions_on_tag"
  add_index "versions", ["user_id", "user_type"], :name => "index_versions_on_user_id_and_user_type"
  add_index "versions", ["user_name"], :name => "index_versions_on_user_name"
  add_index "versions", ["versioned_id", "versioned_type"], :name => "index_versions_on_versioned_id_and_versioned_type"

  create_table "videoconference_subscriptions", :force => true do |t|
    t.integer  "status"
    t.integer  "user_id"
    t.integer  "shopping_cart_id"
    t.string   "paypal_profileid"
    t.string   "paypal_profilestatus"
    t.string   "paypal_correlationid"
    t.datetime "last_payment_date"
    t.datetime "expiration_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "videoconferences", :force => true do |t|
    t.integer  "user_id"
    t.string   "room_number"
    t.string   "topic"
    t.integer  "duration"
    t.datetime "start_time"
    t.string   "timezone"
    t.string   "friendly_url"
    t.string   "password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "room_id"
  end

  create_table "websites", :force => true do |t|
    t.integer "card_id"
    t.string  "name"
    t.integer "account_type", :default => 0
  end

end
