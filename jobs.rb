#!/usr/bin/env ruby
# frozen_string_literal: true

require 'beaneater'
require 'uri'

MAX_JOBS = 25

def beanstalk_url
  return ARGV[0] if ARGV

  'beanstalk://127.0.0.1/'
end

def max_jobs
  return ARGV[1] if ARGV && ARGV[1].to_i.positive?

  MAX_JOBS
end

def beanstalk_address
  uri = URI.parse(beanstalk_url)
  raise Error, "Bad URL: #{beanstalk_url}" unless uri.scheme = 'beanstalk'

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

puts "Checking tubes on #{beanstalk_url}, max allowed jobs: #{max_jobs}"
puts jobs_hash
