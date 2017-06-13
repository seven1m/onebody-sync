#!/usr/bin/env ruby

USER_EMAIL = 'you@example.com'
USER_KEY = 'abcdef1234567890abcdef1234567890abcdef1234567890ab'
URL = 'http://members.mychurch.com'

IMPORT_SETTINGS = {
  match_strategy: 'by_id_only', # other options are by_name, by_contact_info, by_name_or_contact_info
  create_as_active: '0',        # assuming you'll use a column in your CSV called "status" to set this
  overwrite_changed_emails: '0' # set to '1' if you want to always blow away changed email addresses
}

require 'bundler'
Bundler.require

require 'cgi'
require 'csv'
require 'json'

def full_url(url, path = '')
  url.sub(/https?:\/\//, "\\0#{CGI.escape(USER_EMAIL)}:#{USER_KEY}@") + path
end

unless (filename = ARGV.first)
  puts 'You must specify the path to your csv file'
  exit(1)
end

data = File.read(filename, encoding: 'ASCII-8BIT')
headings = CSV.parse(data)[0]

puts 'uploading file'
RestClient.post(full_url(URL, '/admin/imports'), file: File.open(filename)) do |response|
  location = begin
               full_url(response.headers[:location])
             rescue
               raise(response)
             end

  puts 'parsing file'
  begin
    sleep 1
    resp = JSON.parse(RestClient.get(location + '.json'))
    print "  #{resp['row_progress']}%\r"
  end while %w[pending parsing].include?(resp['status'])

  raise resp['error_message'] if resp['status'] == 'errored'

  puts 'executing import'
  settings = IMPORT_SETTINGS.merge(
    mappings: headings.each_with_object({}) { |k, h| h[k] = k }
  )
  RestClient.patch(location, status: 'matched', import: settings, dont_preview: '1') do |response|
    raise response unless response.headers[:location]
    location = full_url(response.headers[:location]) + '.json'
    begin
      sleep 1
      resp = JSON.parse(RestClient.get(location))
      print "  #{resp['row_progress']}%\r"
    end while %w[previewed active].include?(resp['status'])

    raise resp['error_message'] if resp['status'] == 'errored'

    puts '  100%'
    puts response.headers[:location]
  end
end
