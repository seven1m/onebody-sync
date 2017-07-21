# list statuses here to define a person's status in OneBody
# any status not listed will cause a person to be 'inactive' in OneBody

STATUSES = {
  pending: [
    'Visitor'
  ],
  active: [
    'Member - Active',
    'Non-Member - Active'
  ]
}.freeze

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require 'bundler'
Bundler.require

require 'csv'

COLUMNS = %w[
  legacy_id
  first_name
  middle_name
  last_name
  suffix
  email
  alternate_email
  gender
  child
  birthday
  date2
  date3
  date4
  date5
  date6
  date7
  date8
  date9
  date10
  date11
  date12
  status
  sequence
  mobile_phone
  work_phone
  fax
  note1
  note2
  note3
  note4
  note5
  family_legacy_id
  family_name
  family_last_name
  family_address1
  family_address2
  family_city
  family_state
  family_zip
  family_country
].freeze

(DATA_PATH, OUT_PATH) = ARGV

unless DATA_PATH && OUT_PATH
  puts 'ERROR: You must pass path to database and path for output csv file'
  exit 1
end

me = DBF::Table.new(File.join(DATA_PATH, 'me.dbf'))
ma = DBF::Table.new(File.join(DATA_PATH, 'ma.dbf'))
me_codes = DBF::Table.new(File.join(DATA_PATH, 'macodes.dbf'))

CODES = me_codes.each_with_object({}) do |code, hash|
  hash[code['FIELD']] ||= {}
  hash[code['FIELD']][code['CODE']] = code['DESCRIPT']
end

families = ma.each_with_object({}) { |f, h| h[f['MAIL_NO']] = f }

def format_date(date)
  date && date.strftime('%Y-%m-%d')
end

def status(code)
  description = CODES.fetch('CATEGORY', {})[code]
  if (found = STATUSES.detect { |_, matching| matching.include?(description) })
    found.first.to_s
  else
    'inactive'
  end
end

CSV.open(OUT_PATH, 'w') do |csv|
  csv << COLUMNS
  me.each do |person|
    print '.'
    family = families[person['MAIL_NO']]
    csv << [
      person['PERS_NO'],
      person['FIRSTNAME'].strip,
      person['MIDDLENAME'].strip,
      person['LASTNAME'].strip,
      person['SUFFIX'].strip,
      person['E_MAIL'].strip,
      person['E_MAIL2'].strip,
      person['M_F'].strip,
      { 'Y' => 'false', 'N' => 'true' }[person['ADULT'].strip],
      format_date(person['BORN']),
      format_date(person['DATE2']),
      format_date(person['DATE3']),
      format_date(person['DATE4']),
      format_date(person['DATE5']),
      format_date(person['DATE6']),
      format_date(person['DATE7']),
      format_date(person['DATE8']),
      format_date(person['DATE9']),
      format_date(person['DATE10']),
      format_date(person['DATE11']),
      format_date(person['DATE12']),
      status(person['STATUS']),
      person['PERS_NO'],
      person['MEPHN3'],
      person['MEPHN1'],
      person['MEPHN2'],
      person['NOTE1'],
      person['NOTE2'],
      person['NOTE3'],
      person['NOTE4'],
      person['NOTE5'],
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
