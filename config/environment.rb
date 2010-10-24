
require "#{File.dirname(__FILE__)}/../lib/crabgrass/info.rb"

info "LOAD FRAMEWORK"
RAILS_GEM_VERSION = '~> 2.3.0'  # Use any Rails in the 2.3.x series 
require File.join(File.dirname(__FILE__), 'boot')
require "#{RAILS_ROOT}/lib/crabgrass/boot.rb"

Crabgrass::Initializer.run do |config|
  info "LOAD CONFIG BLOCK"

  config.load_paths += %w(activity assets associations discussion chat observers profile poll task tracking requests mailers).collect{|dir|"#{RAILS_ROOT}/app/models/#{dir}"}
  config.load_paths << "#{RAILS_ROOT}/app/permissions"
  config.load_paths << "#{RAILS_ROOT}/app/sweepers"
  config.load_paths << "#{RAILS_ROOT}/app/helpers/classes"

  # this is required because we have a mysql specific fulltext index.
  config.active_record.schema_format = :sql

    # Activate observers that should always be running
  config.active_record.observers = :user_observer, :membership_observer,
    :group_observer, :relationship_observer, :post_observer, :page_tracking_observer,
    :request_to_destroy_our_group_observer

  config.action_controller.session_store = :cookie_store #:mem_cache_store # :p_store

  # store fragments on disk, we might have a lot of them.
  config.action_controller.cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"

  # Make Active Record use UTC-base instead of local time
  config.time_zone = 'UTC'
  config.active_record.default_timezone = :utc

  # allow plugins in more places
  ['vendor/crabgrass_plugins', 'extensions/mods', 'extensions/pages'].each do |path|
    config.plugin_paths << "#{RAILS_ROOT}/#{path}"
  end

  # Deliveries are disabled by default. Do NOT modify this section.
  # Define your email configuration in email.yml instead.
  # It will automatically turn deliveries on
  config.action_mailer.perform_deliveries = false

  ##
  ## GEMS
  ## see environments/test.rb for testing specific gems
  ##

  # required, included with crabgrass
  config.gem 'riseuplabs-greencloth', :lib => 'greencloth'
  config.gem 'riseuplabs-undress', :lib => 'undress/greencloth'
  config.gem 'riseuplabs-uglify_html', :lib => 'uglify_html'

  # required, but not included with crabgrass:
  config.gem 'thinking-sphinx', :lib => 'thinking_sphinx', :version => '1.3.19'
  config.gem 'will_paginate', :version => '2.3.14'
  config.gem 'mini_magick', :version => '2.3'
  config.gem 'compass', :version => '0.10.4'
  config.gem 'compass-susy-plugin', :lib => 'susy', :version => '0.8.1'

  # required, and need a build environment to install
  config.gem 'haml'
  config.gem 'RedCloth'

  # See Rails::Configuration for more options
end

