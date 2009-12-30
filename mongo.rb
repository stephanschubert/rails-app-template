# Wrap template commands in block so their execution can be tested.

def template(&block)
  @store_template = block
end

template do

  # Configuration
  app_name = File.basename(root)
  app_db   = app_name.gsub(/[-\s]/, "_").downcase

  # Delete unnecessary files
  rm "README"
  rm "public/index.html"
  rm "public/favicon.ico"
  rm "public/images/rails.png"
  rm_rf "public/javascripts/*"
  rm_rf "test"

  # Setup new README
  file "README", "= #{app_name}"

  # Setup .gitignore file
  append_file ".gitignore", <<-EOS.gsub(/^  /, '')
  tmp/**/*
  log/*.log
  doc/api
  doc/app
  EOS

  # Gems for test environment
  gem_with_version "spork", :lib => false, :env => 'test'
  gem_with_version "webrat", :lib => false, :env => 'test'
  gem_with_version "rspec", :lib => false, :env => 'test'
  gem_with_version "rspec-rails", :lib => 'spec/rails', :env => 'test'
  gem_with_version "remarkable_rails", :lib => false, :env => 'test'
  gem_with_version 'bmabey-email_spec', :source => 'http://gems.github.com', :lib => 'email_spec', :env => 'test'
  gem_with_version 'thoughtbot-factory_girl', :source => 'http://gems.github.com', :lib => 'factory_girl', :env => 'test'
  gem_with_version 'fakeweb', :env => 'test'

  # Make sure all these gems are actually installed locally
  run "sudo rake gems:install RAILS_ENV=test"

  generate "rspec"
  generate "email_spec"

  # Set up spork
  run "spork --bootstrap"

  # Set up remarkable_rails
  append_file "spec/spec_helper.rb", <<-EOS.gsub(/^  /, '')
  require "remarkable_rails"
  EOS

  # Gems for cucumber environment
  generate "cucumber --spork"
  remove_gems :env => 'cucumber'
  gem_with_version "spork", :lib => false, :env => 'cucumber'
  gem_with_version "aslakhellesoy-cucumber", :lib => false, :env => 'cucumber'
  gem_with_version "webrat", :lib => false, :env => 'cucumber'
  gem_with_version "rspec", :lib => false, :env => 'cucumber'
  gem_with_version "rspec-rails", :lib => 'spec/rails', :env => 'cucumber'
  gem_with_version "remarkable_rails", :lib => false, :env => 'cucumber'
  gem_with_version 'bmabey-email_spec', :source => 'http://gems.github.com', :lib => 'email_spec', :env => 'cucumber'
  gem_with_version 'thoughtbot-factory_girl', :source => 'http://gems.github.com', :lib => 'factory_girl', :env => 'cucumber'
  gem_with_version 'fakeweb', :env => 'cucumber'

  # Make sure all these gems are actually installed locally
  run "sudo rake gems:install RAILS_ENV=cucumber"

  # Install submoduled plugins
  plugin "haml",
  :git => "git://github.com/nex3/haml.git", :submodule => true

  plugin "jrails",
  :git => "git://github.com/aaronchi/jrails.git", :submodule => true

  plugin "make_resourceful",
  :git => "git://github.com/hcatlin/make_resourceful.git", :submodule => true

  plugin "will_paginate",
  :git => "git://github.com/mislav/will_paginate.git", :submodule => true

  plugin 'rails_footnotes',
  :git => 'git://github.com/josevalim/rails-footnotes.git', :submodule => true

  plugin 'blue_ridge',
  :git => 'git://github.com/relevance/blue-ridge.git', :submodule => true

  plugin 'formtastic',
  :git => 'git://github.com/justinfrench/formtastic.git', :submodule => true

  generate "blue_ridge"

  # JRails' install script doesn't work correctly for some time, so
  # let's copy the files ourselves..
  # run "ruby vendor/plugins/jrails/install.rb"

  run "cp vendor/plugins/jrails/javascripts/*.js public/javascripts/"
  
  # Setup HAML initializer
  initializer 'haml.rb', <<-EOS.gsub(/^  /, '')
  Haml::Template::options.update({

    # Render HTML DOCTYPE and affects tag rendering.
    # We don't really want XHTML due to several exotic
    # bugs and problems.
    :format => :html4,
                                 
    # Double-quote attributes
    :attr_wrapper => '"',
                                 
    # Always escape HTML.
    # To prevent escaping use '!='                                 
    :escape_html => true                                 
  })

  if Rails.env.production?
    # Minimal whitespace in CSS files.
    Sass::Plugin.options[:style] = :compact
  
    # Render CSS from SASS when the application starts.
    Sass::Plugin.update_stylesheets
  end

  module StandardistaHelper

    # Overrides the tag helper from Rails to disable self-closing
    # tags which don't belong to HTML.
    def tag(name, options = nil, open = false, escape = true)
      "<\#\{name\}\#\{tag_options(options, escape) if options\}>"
    end
  end

  ActionView::Base.send :include, StandardistaHelper
  EOS

  # Setup simple application layout
  file "app/views/layouts/default.html.haml", <<-EOS.gsub(/^  /, '')
  !!! strict
  %html
    %head
      %title= "#{app_name}"
    %body
      = yield
  EOS

  # Set up factory_girl's sequences/factories
  append_file 'features/support/env.rb', <<-EOS.gsub(/^  /, '')
  require "email_spec/cucumber"
  require File.dirname(__FILE__) + "/../../spec/sequences"
  require File.dirname(__FILE__) + "/../../spec/factories"
 
  Before do
    FakeWeb.allow_net_connect = false
  end
  EOS
  
  append_file 'spec/spec_helper.rb', <<-EOS.gsub(/^  /, '')
  require File.dirname(__FILE__) + '/sequences'
  require File.dirname(__FILE__) + '/factories'
  EOS

  run "touch spec/sequences.rb"
  run "touch spec/factories.rb"

  # Set up sessions controller
  generate "rspec_controller", "sessions new create destroy"

  file "app/controllers/sessions_controller.rb", <<-EOS.gsub(/^  /, "")
  class SessionsController < ApplicationController
    def new
    end

    def create
    end

    def destroy
    end

    private

    def logged_in?
      session[:user_id]
    end
  end
  EOS

  # Set up protected controller
  generate "rspec_controller", "protected"

  file "app/controllers/protected_controller.rb", <<-EOS.gsub(/^  /, "")
  class ProtectedController < SessionsController
    before_filter :require_login

    private

    def require_login
      redirect_to(login_url) unless logged_in?
    end
  end
  EOS

  # Set up routes

  route "map.resource :session"
  route "map.login '/login', :controller => 'sessions', :action => 'new'"

  # Commit all work so far
  git :submodule => "init"
  git :add => "."
  git :commit => "-a -m 'Applied github.com/jazen/rails-app-template/mongo.rb'"
end

# Helpers

def gem_with_version(name, options = {})
  if gem_spec = Gem.source_index.find_name(name).last
    version = gem_spec.version.to_s
    gem(name, options.merge(:version => ">=#{version}"))
  else
    $stderr.puts "ERROR: cannot find gem #{name}; cannot load version. Adding it anyway."
    gem(name, options)
  end
end
 
def remove_gems(options)
  env = options.delete(:env)
  gems_code = /^\s*config.gem.*\n/
  file = env.nil? ? 'config/environment.rb' : "config/environments/#{env}.rb"
  gsub_file file, gems_code, ""
end

def rm(file)
  run "rm #{file}"
end

def rm_rf(dir)
  run "rm -rf #{dir}"
end

def run_template
  @store_template.call
end
 
# Hold off running the template whilst in unit testing mode
run_template unless ENV['TEST_MODE'] 
