#!/usr/bin/env ruby
require 'yaml'
require 'bunny'
require 'recursive-open-struct'

def main
  settings = configure()
  bunny = connect(settings)
  ch = bunny.create_channel
  q = ch.queue("tts.utterances")
  x = ch.default_exchange
  utterances = ARGV.dup
  utterances.each { |u| x.publish(u, :routing_key => q.name) }
  bunny.close
    
end

def configure
  # Load YAML file
  settings = RecursiveOpenStruct.new(
    YAML.load(File.read(File.dirname(__FILE__) + '/../etc/settings.yaml')),
    recurse_over_arrays: true
  )
end

def connect(settings)
  bunny = Bunny.new(
    settings.rmq_creds.url + '/' + settings.rmq_creds.vhost,
  )
  bunny.start
  bunny
end


main()

