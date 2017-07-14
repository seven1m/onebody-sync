require 'bundler'
Bundler.require

require 'csv'

COLUMNS = %w(
  legacy_id
  first_name
  last_name
  birthday
  email
  family_legacy_id
  family_name
  family_last_name
  family_address1
  family_address2
  family_city
  family_state
  family_zip
  family_country
).freeze

(DATA_PATH, OUT_PATH) = ARGV

unless DATA_PATH && OUT_PATH
  puts 'ERROR: You must pass path to database and path for output csv file'
  exit 1
end

me = DBF::Table.new(File.join(DATA_PATH, 'me.dbf'))
ma = DBF::Table.new(File.join(DATA_PATH, 'ma.dbf'))

families = ma.each_with_object({}) { |f, h| h[f['MAIL_NO']] = f }

CSV.open(OUT_PATH, 'w') do |csv|
  csv << COLUMNS
  me.each do |person|
    print '.'
    family = families[person['MAIL_NO']]
    csv << [
      person['PERS_NO'],
      person['FIRSTNAME'].strip,
      person['LASTNAME'].strip,
      person['BORN'] && person['BORN'].strftime('%Y-%m-%d'),
      person['E_MAIL'].strip,
      person['MAIL_NO'],
      family['NAMELINE'].strip,
      family['LASTNAME'].strip,
      family['ADDRESS'].strip,
      family['ADDRESS2'].strip,
      family['CITY'].strip,
      family['STATE'].strip,
      family['ZIP'].strip,
      family['COUNTRY'].strip
    ]
  end
end

puts
puts 'done'
