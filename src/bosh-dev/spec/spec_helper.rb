require File.expand_path('../../../spec/shared/spec_helper', __FILE__)

require 'rake'
require 'fakefs/spec_helpers'
require 'webmock/rspec'
require 'sequel'
require 'support/buffered_logger'

Dir.glob(File.expand_path('../support/**/*.rb', __FILE__)).each { |f| require(f) }
