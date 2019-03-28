#!/usr/bin/env ruby
#
#  Usage: ruby jobs.rb <url> <max_jobs>
#  e.g. ruby jobs.rb beanstalk://127.0.0.1/ 25

require 'beaneater'
require 'uri'

MAX_JOBS = 25

def beanstalk_url
  return ARGV[0] if ARGV.any?

  'beanstalk://127.0.0.1/'
end

def max_jobs
  if ARGV && ARGV[1].to_i > 0
    return ARGV[1].to_i
  end

  MAX_JOBS
end

def beanstalk_address
  uri = URI.parse(beanstalk_url)

  if uri.scheme != 'beanstalk'
    raise StandardError, "Bad URL: #{beanstalk_url}"
  end

  "#{uri.host}:#{uri.port || 11300}"
end

def beanstalk
  @beanstalk ||= Beaneater.new(beanstalk_address)
end

def jobs_hash
  result = {}
  beanstalk.tubes.each do |tube|
    jobs = tube.peek(:ready)
    count = jobs.nil? ? '0' : jobs.length
    result[tube.name] = count
  end
  result
end

def run
  begin
    result = jobs_hash.values.any? { |v| v.to_i > max_jobs }
    case result
    when true
      puts '1'
    else
      puts '0'
    end
  rescue StandardError
    puts '3'
  end
end

run
