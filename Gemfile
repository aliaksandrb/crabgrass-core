
source :rubygems

gem 'rails', '~> 3.0.20'

gem 'rake', '~> 0.9.2'

gem 'prototype_legacy_helper', '0.0.0', :git => 'git://github.com/rails/prototype_legacy_helper.git'

## from config/environment.rb

# required, but not included with crabgrass:
gem 'i18n'#, '~> 0.5'
gem 'thinking-sphinx', '~> 2.0', :require => 'thinking_sphinx'
gem 'will_paginate', '~> 3.0'
gem 'sprockets', '~> 2.2'

gem 'mysql', '2.8.1'

# required, and compilation is required to install
gem 'RedCloth', '~> 4.2'
gem 'hpricot', '~> 0.8'

# required, included with crabgrass
gem 'greencloth', :require => 'greencloth', :path => 'vendor/gems/riseuplabs-greencloth-0.1'
gem 'undress', :require => 'undress/greencloth', :path => 'vendor/gems/riseuplabs-undress-0.2.4'
gem 'uglify_html', :require => 'uglify_html', :path => 'vendor/gems/riseuplabs-uglify_html-0.12'

# not required, but a really good idea
gem 'mime-types', :require => 'mime/types'

gem 'delayed_job', '~> 3.0.5'

gem 'rails3_before_render'

group :production, :development do
  gem 'compass', '0.10.6'
  gem 'haml', '~> 3.0'
  gem 'sass', '~> 3.2'
  gem 'compass-susy-plugin', :require => 'susy', :path => 'vendor/gems/compass-susy-plugin-0.8.1'
  gem 'whenever'
  gem 'jsmin'
end

group :development do
  ##
  ## needed for some rake tasks, but not generally.
  ##
  gem 'rdoc', '~> 3.0'

  gem 'mongrel'
end

group :test, :development do
  gem 'ruby-debug'
end


## from config/environments/test.rb
group :test do

  ##
  ## GEMS REQUIRED FOR TESTS
  ##

  gem 'machinist', '~> 1.0' # switch to v2 when stable.
  gem 'faker', '~> 1.0.0'
  gem 'minitest', '~> 2.12', :require => 'minitest/autorun'
  gem 'mocha', '~> 0.12.0', :require => false
  #
  # mocha note: mocha must be loaded after the things it needs to patch.
  #             so, we skip the 'require' here, and do it later.
  #

  ##
  ## GEMS REQUIRED FOR FUNCTIONAL TESTS
  ##

  # FIXME: figure out if we're unit testing.
  #unless defined?(UNIT_TESTING)
    gem 'compass', '0.10.6'
    gem 'haml', '~> 3.0'
    gem 'compass-susy-plugin', :require => 'susy', :path => 'vendor/gems/compass-susy-plugin-0.8.1'
  #end

  #gem 'webrat'

end
