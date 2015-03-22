source 'https://rubygems.org'

##
#  Core components
##

# Rails is the framework we use.
# use the 3.2 series including all security fixes
gem 'rails', '~> 3.2.19'

# Rake is rubys make... performing tasks
# locking in to latest major to fix API
gem 'rake', '~> 10.0', :require => false

##
# Prototype - yes. we still use it.
# these will be replaced by jquery equivalents at some point:
##

# main part of prototype
# locking so it matches rails version
gem 'prototype-rails', '~> 3.2.1'

# legacy helper for form_remote_for and link_to_remote
# there's only a 0.0.0 version out there it seems
gem 'prototype_legacy_helper', '0.0.0',
  :github => 'rails/prototype_legacy_helper'

##
# Upgrade pending
##

# Full text search for the database
# thinking-sphinx version 3 requires activerecord >= 3.1 which we have now
# It also requires sphinx >= 2.06 and probably changes the API
# so, we bind to the latest in the version 2 series for now
gem 'thinking-sphinx', '~> 2.1.0', :require => 'thinking_sphinx'

# Enhanced Tagging lib. Used to tag pages
# Could not get the migration rake task for acts-as-taggable-on 3.x to work
# before rails 3.2.
# So we should run the migration and upgrade now that we are on rails 3.2
gem 'acts-as-taggable-on', '~> 2.4.1'

##
#  Backported from rails 4
##

# add a digest of a template and its dependencies to the cache key
# not developed anymore. Fixing major version never the less.
gem 'cache_digests', '~> 0.3'

# protect against malicious parameters by explicitly permitting the ones we want
# part of rails 4, looks like the rails3 version is not in active dev.
gem 'strong_parameters', '~> 0.2'

##
#  Required, but not included with crabgrass:
##

# translating strings for the user interface
# locking in to latest major to fix API
gem 'i18n', '~> 0.6'

# improved gem to access mysql database
# locking in to latest major to fix API
gem 'mysql2', '~> 0.3'

# parsing and generating JSON
# locking in to latest major to fix API
gem 'json', '~> 1.8'

# Markup language that uses indent to indicate nesting
# locking in to latest major to fix API
gem 'haml', '~> 4.0'

# Extendet scriptable CSS language
# locking in to latest major to fix API
gem 'sass'

# ?
# locking in to latest major to fix API
gem 'http_accept_language', '~> 2.0'

# Pagination for lists with a lot of items
# 3.0.7 introduced a bug: https://github.com/mislav/will_paginate/issues/400
# we should remove this strict version once that is fixed.
gem 'will_paginate', '= 3.0.6'

# state-machine for requests
# locking in to latest major to fix API
gem 'aasm' , '~> 3.4'

# lists used for tasks and choices in votes so far
# continuation of the old standart rails plugin
# locking in to latest major to fix API, not really maintained though
gem 'acts_as_list', '~> 0.4'

# Check the format of email addresses against RFCs
# better maintained than validates_as_email
# locking in to latest major to fix API
gem 'validates_email_format_of', '~> 1.6'

##
## GEMS required, and compilation is required to install
##

# Formatting text input
# We extend this to resolve links locally -> GreenCloth
# locking in to latest major to fix API
gem 'RedCloth', '~> 4.2'

# HTML parser used inside our own uglify gem
# Deprecated by the original maintainers
# TODO: replace with nokogiri
gem 'hpricot', '~> 0.8'

##
## GEMS required, included with crabgrass
##

# extension of the redcloth markup lang
gem 'greencloth', :require => 'greencloth',
  :path => 'vendor/gems/riseuplabs-greencloth-0.1'

# ?
gem 'undress', :require => 'undress/greencloth',
  :path => 'vendor/gems/riseuplabs-undress-0.2.4'

# ?
gem 'uglify_html', :require => 'uglify_html',
  :path => 'vendor/gems/riseuplabs-uglify_html-0.12'

##
## GEMS not required, but a really good idea
##

# detect mime-types of uploaded files
#
gem 'mime-types', :require => 'mime/types'

# process heavy tasks asynchronously
# TODO: why is this locked to 3.0 ?
gem 'delayed_job', '~> 3.0.5'

# ?
gem 'rails3_before_render'

# unpack file uploads
# TODO: why is this locked to 1.1. ?
gem 'rubyzip', '~> 1.1.0', :require => false

# load new rubyzip, but with the old API.
# TODO: use the new zip api and remove gem zip-zip
gem 'zip-zip', :require => 'zip'

# Assets group according to migration guide:
# http://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html#upgrading-from-rails-3-1-to-rails-3-2
group :assets do
  gem 'sass-rails',   '~> 3.2.6'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier',     '>= 1.0.3'
end

group :production do
  # js runtime needed to precompile assets
  # runs independendly - so no version restriction for now
  # TODO: check if we want this or nodejs
  gem 'therubyracer'
end

group :production, :development do
  # used to install crontab
  gem 'whenever', :require => false
  # used to minify javascript
  # I don't think this is used in production with the Asset Pipeline
  # TODO check if it's needed at all
  gem 'jsmin', :require => false
end

group :development do
  ##
  ## needed for some rake tasks, but not generally.
  ##
  gem 'rdoc', '~> 3.0'

  # fast and light weight server
  gem 'thin', :platforms => :mri_19, :require => false

  # speed up rails dev mode
  gem 'rails-dev-boost', :github => 'thedarkone/rails-dev-boost'

  # used by rails-dev-boost
  gem 'rb-inotify', '~> 0.9', :require => false
end

group :test, :development do
  # as the name says... debug things
  gem 'debugger', :platforms => :mri_19
  gem 'byebug', :platforms => [:mri_20, :mri_21]
end


## from config/environments/test.rb
group :test, :ci do

  ##
  ## GEMS REQUIRED FOR TESTS
  ##

  gem 'factory_girl_rails'
  gem 'faker', '~> 1.0.0'
  gem 'minitest', '~> 2.12', :require => false
  gem 'mocha', '~> 0.12.0', :require => false
  #
  # mocha note: mocha must be loaded after the things it needs to patch.
  #             so, we skip the 'require' here, and do it later.
  #             also, requiring either mocha or minitest here causes zeus to
  #             run tests twice, if using zeus (which you should).
  #

  ##
  ## GEMS REQUIRED FOR INTEGRATION TESTS
  ##

  gem 'capybara', require: false

  # Capybara driver with javascript capabilities using phantomjs
  # locked to major version for stable API
  gem 'poltergeist', '~> 1.5', :require => false

  # Headless webkit browser for testing, fast and with javascript
  # Version newer than 1.8 is required by current poltergeist.
  gem 'phantomjs-binaries', '~> 1.8', :require => false
end
