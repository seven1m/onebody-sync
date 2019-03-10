# The 'Membership Status' of a person affects how they are exported. You can see
# all your church's statuses here: https://people.planningcenteronline.com/customize

# list membership statuses that will be exported; all others will be skipped
STATUSES_TO_EXPORT = [
  'Attender',
  'Child of Member',
  'College',
  'Member',
  'Non Resident Member',
  'Other Child',
  'Other Youth',
  'Prospect',
  'Special Event',
  'Spouse of Member',
  'Visitor'
].freeze

# list "pending" membership statuses in the array below
PENDING_STATUSES = [
  'Other Child',
  'Other Youth',
  'Prospect',
  'Special Event',
  'Visitor'
].freeze

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require 'bundler'
Bundler.require

require 'csv'

OUT_PATH = ARGV.first

unless OUT_PATH && ENV['PCO_APP_ID'] && ENV['PCO_SECRET']
  puts 'Usage:'
  puts 'export PCO_APP_ID=abcdef0123456789abcdef0123456789abcdef012345789abcdef0123456789a'
  puts 'export PCO_SECRET=0123456789abcdef0123456789abcdef012345789abcdef0123456789abcdef0'
  puts 'ruby export.rb out.csv'
  exit 1
end

API = PCO::API.new(basic_auth_token: ENV['PCO_APP_ID'], basic_auth_secret: ENV['PCO_SECRET'])

class String; def presence; strip.empty? ? nil : strip; end; end
class Nil; def presence; nil; end; end

def get_people_page(page: 0, params: {})
  API.people.v2.people.get(
    params.merge(
      'include'  => 'emails,phone_numbers,addresses,households,name_suffix',
      'order'    => 'last_name,first_name',
      'per_page' => 100,
      'offset'   => 100 * page
    )
  )
rescue PCO::API::Errors::ClientError => e
  if e.message =~ /rate limit/i
    sleep 1
    retry
  else
    raise
  end
end

def merge_data(response)
  included_by_type = response['included'].each_with_object({}) do |res, hash|
    hash[res['type']] ||= {}
    hash[res['type']][res['id']] = res
  end
  response['data'].each do |person|
    person['relationships'].each do |key, rel_data|
      if rel_data['data'].is_a?(Array)
        rel_data['data'].each do |rel|
          rel['attributes'] = included_by_type.fetch(rel['type'], {}).fetch(rel['id'], {})['attributes']
        end
      elsif rel_data['data'].is_a?(Hash)
        rel = rel_data['data']
        rel['attributes'] = included_by_type.fetch(rel['type'], {}).fetch(rel['id'], {})['attributes']
      end
    end
  end
  response
end

def each_person(params = {})
  page = 0
  index = 0
  response = get_people_page(page: page, params: params)
  while response['data'].any?
    merge_data(response)['data'].each do |person|
      index += 1
      yield(person, index, response['meta']['total_count'])
    end
    page += 1
    response = get_people_page(page: page, params: params)
  end
end

emails_seen = {}
people = []
STATUSES_TO_EXPORT.each do |status_to_export|
  params = { 'where[membership]': status_to_export }
  params.merge!('where[status]': 'active') if ENV['SKIP_INACTIVE']
  each_person(params) do |person, index, total|
    print "#{status_to_export}: #{index} of #{total}\r"
    emails = person.dig('relationships', 'emails', 'data') || []
    if ENV['NO_EMAILS_FOR_CHILDREN'] && person.dig('attributes', 'child')
      primary_email = alternate_email = {}
    else
      primary_email = emails.detect { |e| e.dig('attributes', 'primary') } || {}
      alternate_email = (emails - [primary_email]).first || {}
    end
    emails_seen[primary_email.dig('attributes', 'address').to_s.downcase] = true
    emails_seen[alternate_email.dig('attributes', 'address').to_s.downcase] = true
    pco_status = person.dig('attributes', 'membership')
    status = PENDING_STATUSES.include?(pco_status) ? 'pending' : person.dig('attributes', 'status')
    phones = person.dig('relationships', 'phone_numbers', 'data') || []
    addresses = person.dig('relationships', 'addresses', 'data') || []
    home_address = addresses.detect { |e| e.dig('attributes', 'location') == 'Home' } || {}
    (home_street_line1, home_street_line2) = (home_address.dig('attributes', 'street') || '').split(/\n/, 2)
    household = person.dig('relationships', 'households', 'data', 0) ||
                { 'id' => person['id'], 'attributes' => { 'name' => person.dig('attributes', 'last_name') + ' Household' } }
    household_name = household.dig('attributes', 'name').sub(/ Household$/, '')
    people << [
      person['id'],
      person.dig('attributes', 'first_name'),
      person.dig('attributes', 'last_name'),
      person.dig('relationships', 'name_suffix', 'data', 'value'),
      primary_email.dig('attributes', 'address'),
      alternate_email.dig('attributes', 'address'),
      { 'M' => 'Male', 'F' => 'Female' }[person.dig('attributes', 'gender')],
      person.dig('attributes', 'child'),
      person.dig('attributes', 'birthdate'),
      status,
      (phones.detect { |e| e.dig('attributes', 'location') == 'Mobile' } || {}).dig('attributes', 'number'),
      (phones.detect { |e| e.dig('attributes', 'location') == 'Work' } || {}).dig('attributes', 'number'),
      household['id'],
      household_name,
      household_name,
      home_street_line1,
      home_street_line2,
      home_address.dig('attributes', 'city'),
      home_address.dig('attributes', 'state'),
      home_address.dig('attributes', 'zip').to_s[0...5].presence,
      (phones.detect { |e| e.dig('attributes', 'location') == 'Home' } || {}).dig('attributes', 'number')
    ]
  end
  puts
end

CSV.open(OUT_PATH, 'w') do |csv|
  csv << %w[
    legacy_id
    first_name
    last_name
    suffix
    email
    alternate_email
    gender
    child
    birthday
    status
    mobile_phone
    work_phone
    family_legacy_id
    family_name
    family_last_name
    family_address1
    family_address2
    family_city
    family_state
    family_zip
    family_home_phone
  ]
  people.each do |record|
    record[5] = nil if emails_seen[record[5].to_s.downcase] # alternate email cannot duplicate other primary emails
    csv << record
  end
end

puts 'done'
