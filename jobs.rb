#!/usr/bin/env ruby
#
#  Usage: ruby jobs.rb <url> <warning_max_jobs> <critical_max_jobs>
#  e.g. ruby jobs.rb beanstalk://127.0.0.1/ 25 50

require 'beaneater'
require 'uri'
require 'pry'

WARNING_MAX_JOBS = 25
CRITICAL_MAX_JOBS = 50

def beanstalk_url
  return ARGV[0] if ARGV.any?

  'beanstalk://127.0.0.1/'
end

def warning_max_jobs
  if ARGV.any? && ARGV[1].to_i > 0
    return ARGV[1].to_i
  end

  WARNING_MAX_JOBS
end

def critical_max_jobs
  if ARGV.any? && ARGV[2].to_i > 0
    return ARGV[2].to_i
  end

  CRITICAL_MAX_JOBS
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
    if jobs_hash.values.any? { |v| v.to_i > critical_max_jobs }
      exit 2
    elsif jobs_hash.values.any? { |v| v.to_i > warning_max_jobs }
      exit 1
    else
      exit 0
    end
  rescue StandardError
    exit 3
  end
end

run
