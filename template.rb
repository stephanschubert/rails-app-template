# Setup a fresh Rails application with git
# Use my sake task git:hub:rails:new_app for example.

# Delete unnecessary files

run "rm README"
run "rm public/index.html"

# Install submoduled plugins

plugin "rspec", 
  :git => "git://github.com/dchelimsky/rspec.git", :submodule => true
plugin "rspec-rails",
  :git => "git://github.com/dchelimsky/rspec-rails.git", :submodule => true
plugin => "factory_girl", 
  :git => "git://github.com/thoughtbot/factory_girl.git", :submodule => true

# Generators

generate("rspec")

# Commit to git

git :add => "."
git :commit => "-a -m 'Applied application template from github.com/jazen/rails-app-template'"

# More to come.