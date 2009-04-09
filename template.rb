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

generate "rspec"

plugin "factory_girl", 
  :git => "git://github.com/thoughtbot/factory_girl.git", :submodule => true

plugin "remarkable",
  :git => "git://github.com/carlosbrando/remarkable.git", :submodule => true

plugin "haml",
  :git => "git://github.com/nex3/haml.git", :submodule => true

plugin "acts_as_list",
  :git => "git://github.com/rails/acts_as_list.git", :submodule => true

plugin "acts_as_tree",
  :git => "git://github.com/rails/acts_as_tree.git", :submodule => true

plugin "jrails",
  :git => "git://github.com/aaronchi/jrails.git", :submodule => true

run "ruby vendor/plugins/jrails/install.rb"

plugin "asset_packager",
  :git => "git://github.com/sbecker/asset_packager.git", :submodule => true

run "ruby vendor/plugins/asset_packager/install.rb"

plugin "will_paginate",
  :git => "git://github.com/mislav/will_paginate.git", :submodule => true


# Patch sqlite3 to support in-memory databases, 
# so the testsuite will run much faster.

plugin "memory_test_fix",
  :git => "git://github.com/rsl/memory_test_fix.git", :submodule => true

patched = File.read("config/database.yml").sub!(/db\/test\.sqlite3/, '":memory:"')
File.open("config/database.yml", "w") do |f|
  f.write(patched)
end




# Commit to git

git :add => "."
git :commit => "-a -m 'Applied application template from github.com/jazen/rails-app-template'"

# More to come.