require 'sneakers'
require 'yaml'
require 'recursive-open-struct'

$settings = nil

def configure
  # Load YAML file
  $settings = RecursiveOpenStruct.new(
    YAML.load(File.read(File.dirname(__FILE__) + '/etc/settings.yaml')),
    recurse_over_arrays: true
  )
  
  # Configure RMQ settings for sneakers
  Sneakers.configure(
    :heartbeat => 30,
    :amqp => $settings.rmq_creds.url,
    :vhost => $settings.rmq_creds.vhost,
    :exchange => 'tts',
    :exchange_type => :direct,
    :queue_options => { durable: false },  # cloudamqp does not allow durable, and the sneaker default is durable
    :workers => 1,
    :threads => 1,
  )

  # Determine command to run to speak
  case RbConfig::CONFIG['build']
  when /darwin/
    $settings.local_speech_command = $settings.speech_command.mac_os
  when /arm-.*linux/
    $settings.local_speech_command = $settings.speech_command.raspian
  else
    fail "I only support Macs and Raspberry Pi."
  end
  
end

class Talker
  include Sneakers::Worker
  from_queue :'tts.utterances'

  def work(msg)
    `#{$settings.local_speech_command} '#{msg}'`
    ack!
  end
end

configure()
