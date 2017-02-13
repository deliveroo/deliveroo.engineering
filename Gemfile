source 'https://rubygems.org'

ruby '2.3.1'

require 'json'
require 'open-uri'
versions = JSON.parse(open('https://pages.github.com/versions.json').read)

gem 'github-pages', versions['github-pages'], group: :jekyll_plugins

# Set us up to reload pages interactively
gem 'guard-jekyll-plus'
gem 'guard-livereload'
