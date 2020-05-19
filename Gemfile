source 'https://rubygems.org'

gem 'rails', '~> 5.2', '>= 5.2.4.3'
gem "jquery-rails", "~> 4.0", ">= 4.0.1"

gem 'haml-rails', '~> 0.5', '>= 0.5.3'

#Search
gem 'sunspot_mongoid2', '>= 0.5.1.5'
gem 'sunspot_solr'
gem 'sunspot_cell', :git => 'git://github.com/zheileman/sunspot_cell.git'
gem 'sunspot_cell_jars'
gem 'progress_bar'

#Representers
# gem 'roar', '~> 0.11.19'
gem 'roar-rails', '0.1.0'
gem 'billit_representers', '0.9.0'
gem 'will_paginate', '~> 3.0'

#Dates
gem 'business_time', '>= 0.7.1'

#Clean ruby syntax for writing and deploying cron jobs
gem 'whenever', '>= 0.9.2', :require => false

group :development, :test do
  gem 'rspec-rails', '>= 2.13.2'
  gem 'factory_girl_rails', '>= 4.2.1'
  gem 'guard-bundler'
  gem 'guard-rails'
  gem 'guard-rspec'
  gem 'awesome_print'
  gem 'newrelic_rpm'
end

group :test do
  gem 'database_cleaner'
  gem 'faker'
  gem 'webmock'
end
