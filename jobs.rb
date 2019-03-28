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
    raise StandardError
  end

  "#{uri.host}:#{uri.port || 11300}"
end

def beanstalk
  @beanstalk ||= Beaneater.new(beanstalk_address)
end

def jobs_hash
  result   = {}
  warning  = {}
  critical = {}

  beanstalk.tubes.each do |tube|
    jobs = tube.stats.current_jobs_ready
    critical[tube.name] = jobs if jobs > critical_max_jobs
    warning[tube.name]  = jobs if jobs > warning_max_jobs
  end
  result[:warning]  = warning
  result[:critical] = critical
  result
end

def build_message(hsh, threshold)
  tubes = hsh.map{ |k, v| "#{k} (#{v})" }.join(', ')
  "#{hsh.length} tube(s) are over #{threshold} jobs: #{tubes}"
end

def run
  begin
    if jobs_hash[:critical].values.any?
      puts "CRITICAL: #{build_message(jobs_hash[:critical], critical_max_jobs)}"
      exit 2
    elsif jobs_hash[:warning].values.any?
      puts "WARNING: #{build_message(jobs_hash[:warning], warning_max_jobs)}"
      exit 1
    else
      puts 'OK'
      exit 0
    end
  rescue StandardError
    puts "Bad url: #{beanstalk_url} or beanstalkd unreachable"
    exit 3
  end
end

run
