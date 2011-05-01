unless defined?(FORBIDDEN_NAMES)
  FORBIDDEN_NAMES = %w(account admin assets avatars chat code debug do groups javascripts me networks page pages people places issues session static stats stylesheets theme)
end

#
# :conditions => {:method => :post}
#

ActionController::Routing::Routes.draw do |map|

  ##
  ## STATIC FILES AND ASSETS
  ##

  map.with_options(:controller => 'assets') do |assets|
    assets.connect '/assets/:action/:id', :action => /create|destroy/
    assets.connect 'assets/:id/versions/:version/*path', :action => 'show'
    assets.connect 'assets/:id/*path', :action => 'show'
  end

  map.avatar 'avatars/:id/:size.jpg', :controller => 'avatars', :action => 'show'
  map.connect 'theme/:name/*file.css', :controller => 'theme', :action => 'show'

  ##
  ## ME
  ##

  map.with_options(:namespace => 'me/', :path_prefix => 'me', :name_prefix => 'me_') do |me|
    me.resources :notices
    me.home      '', :controller => 'notices', :action => 'index'
    me.resource  :page, :only => [:new, :create]
    me.pages     'pages/*path', :controller => 'pages'
    me.resources :activities
    me.resources(:discussions, :as => 'messages') do |discussion|
      discussion.resources :posts
    end
    me.resource  :settings, :only => [:show, :update]
    me.resources :permissions
    me.resource  :profile, :controller => 'profile'
    me.resources :requests
    me.resources :avatars
  end

  ##
  ## ENTITIES
  ##

  map.resources :entities, :only => [:index]

#  ##
#  ## PEOPLE
#  ##

#  map.people_directory 'people/directory/*path', :controller => 'people/directory'

#  map.resources :people, :namespace => 'people/' do |people|
#    people.resource  :page, :only => [:new, :create]
#    people.pages     'pages/*path', :controller => 'pages'
#    people.resources :messsages
#    people.resources :activities
#    people.resources :pages
#  end

#  ##
#  ## EMAIL
#  ##

#  map.connect '/invites/:action/*path', :controller => 'requests', :action => /accept/
#  map.connect '/code/:id', :controller => 'codes', :action => 'jump'

  ##
  ## ACCOUNT
  ##

  map.with_options(:controller => 'account') do |account|
    account.reset_password 'account/reset_password/:token', :action => 'reset_password', :token => nil
    account.verify_account 'account/verify_email/:token',   :action => 'verify_email'
    account.new_account    'account/new', :action => 'new'
    account.account        'account/:action/:id'
  end

  map.with_options(:controller => 'session') do |session|
    session.login    'session/login',  :action => 'login'
    session.logout   'session/logout', :action => 'logout'
    session.language 'session/logout', :action => 'language'
    session.session  'session/:action/:id'
  end

#  ##
#  ## GROUP
#  ##

  map.networks_directory 'networks/directory/*path', :controller => 'groups/directory'
  map.groups_directory 'groups/directory/*path', :controller => 'groups/directory'

  map.resources :groups, :networks, :namespace => 'groups/' do |groups|
    groups.resource  :home, :only => [:show]
    groups.resource  :page, :only => [:new, :create]
    groups.pages     'pages/*path', :controller => 'pages' #, :path => []
    groups.resources :members
    groups.resources :committees
    groups.resources :invites
    groups.resources :requests
    groups.resources :permissions
    groups.resources :activities
    groups.resource  :profile, :controller => 'profile'
    groups.resource  :settings, :only => [:show, :update]
    groups.resources :avatars
  end

#  ##
#  ## DEBUGGING
#  ##

  if RAILS_ENV == "development"
    ## DEBUG ROUTE
    map.debug_become 'debug/become', :controller => 'debug', :action => 'become'
  end
  map.debug_report 'debug/report/submit', :controller => 'bugreport', :action => 'submit'

  ##
  ## NORMAL PAGE ROUTES
  ##

  # default page creator
  map.create_page '/pages/create/:type', :controller => 'pages/create', :action => 'new', :type => nil

  # base page
  map.resources :pages, :namespace => 'pages/', :controller => 'base' do |pages|
    pages.resources :participations, :only => [:update, :create]
    pages.resources :changes
    pages.resources :assets
    pages.resources :tags
    pages.resources :posts, :member => {:edit => :any}, :only => [:show, :create, :edit, :update]

    # page sidebar/popup controllers:
    pages.resource :share,      :only => [:show, :update]
    pages.resource :details,    :only => [:show]
    pages.resource :attributes, :only => [:update]
    pages.resource :title,      :only => [:edit, :update], :controller => 'title'
    pages.resource :trash,      :only => [:edit, :update], :controller => 'trash'
  end

  # page subclasses, gets triggered for any controller class Pages::XxxController
  map.connect '/pages/:controller/:page_id/:action', :controller => /.*_page/ # /pages\/[^\/]+/

  ##
  ## DEFAULT ROUTE
  ##

  map.connect '/do/:controller/:action/:id'
  map.root :controller => 'root'

  ##
  ## SPECIAL PATH ROUTES for PAGES and ENTITIES
  ##


  #map.connect '/pages/:controller/:action/:id', :controller => /base_page\/[^\/]+/
  #map.connect 'pages/:_page/:_page_action/:id', :controller => 'dispatch', :action => 'dispatch', :_page_action => 'show', :id => nil

  map.connect ':_context/:_page/:_page_action/:id', :controller => 'dispatch', :action => 'dispatch', :_page_action => 'show', :id => nil
  map.connect ':_context', :controller => 'dispatch', :action => 'dispatch', :_page => nil

end
