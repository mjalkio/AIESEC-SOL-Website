require 'active_support'
require 'rubygems'
require 'bundler'
Bundler.require

require './app.rb'
run Sinatra::Application