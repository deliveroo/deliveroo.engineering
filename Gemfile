source 'https://rubygems.org'

ruby '2.3.1'

require 'json'
require 'open-uri'
versions = JSON.parse(open('https://pages.github.com/versions.json').read)

group :jekyll_plugins do
  gem 'github-pages', versions['github-pages']
  gem 'jekyll-contentblocks'
end

# Set us up to reload pages interactively
gem 'guard-jekyll-plus'
gem 'guard-livereload'
