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
  user1
  user2
  user3
  user4
  user5
  code1
  code2
  code3
  code4
  code5
  classes
  family_legacy_id
  family_name
  family_last_name
  family_address1
  family_address2
  family_city
  family_state
  family_zip
  family_country
  family_home_phone
].freeze

(DATA_PATH, OUT_PATH) = ARGV

unless DATA_PATH && OUT_PATH
  puts 'ERROR: You must pass path to database and path for output csv file'
  exit 1
end

me = DBF::Table.new(File.join(DATA_PATH, 'ME.DBF'))
ma = DBF::Table.new(File.join(DATA_PATH, 'MA.DBF'))
me_codes = DBF::Table.new(File.join(DATA_PATH, 'MECODES.DBF'))
sk_codes = DBF::Table.new(File.join(DATA_PATH, 'SKCODES.DBF'))
sk_ref = DBF::Table.new(File.join(DATA_PATH, 'SKREF.DBF'))
sk = DBF::Table.new(File.join(DATA_PATH, 'SK.DBF'))

ME_CODES = me_codes.each_with_object({}) do |code, hash|
  hash[code['FIELD']] ||= {}
  hash[code['FIELD']][code['CODE']] = code['DESCRIPT']
end

SK_CODES = sk_codes.each_with_object({}) do |code, hash|
  hash[code['CODE']] = code['DESCRIPT']
end

SKILL_NAMES = sk_ref.each_with_object({}) do |code, hash|
  hash[code['SKILL_NO']] = code['DESC']
end

SKILLS = sk.each_with_object({}) do |code, hash|
  hash[code['PERS_NO']] ||= []
  role = SK_CODES[code['ROLE']]
  hash[code['PERS_NO']] << "sk#{code['SKILL_NO']}[#{role}]"
end

families = ma.each_with_object({}) { |f, h| h[f['MAIL_NO']] = f }

def format_date(date)
  date && date.strftime('%Y-%m-%d')
end

def status(code)
  description = ME_CODES.fetch('STATUS', {})[code]
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
      ME_CODES.fetch('USER1', {})[person['USER1']],
      ME_CODES.fetch('USER2', {})[person['USER2']],
      ME_CODES.fetch('USER3', {})[person['USER3']],
      ME_CODES.fetch('USER4', {})[person['USER4']],
      ME_CODES.fetch('USER5', {})[person['USER5']],
      ME_CODES.fetch('CODE1', {})[person['CODE1']],
      ME_CODES.fetch('CODE2', {})[person['CODE2']],
      ME_CODES.fetch('CODE3', {})[person['CODE3']],
      ME_CODES.fetch('CODE4', {})[person['CODE4']],
      ME_CODES.fetch('CODE5', {})[person['CODE5']],
      (SKILLS[person['PERS_NO']] || []).join(','),
      person['MAIL_NO'],
      family['NAMELINE'].strip,
      family['LASTNAME'].strip,
      family['ADDRESS'].strip,
      family['ADDRESS2'].strip,
      family['CITY'].strip,
      family['STATE'].strip,
      family['ZIP'].strip,
      family['COUNTRY'].strip,
      family['PHONE1']
    ]
  end
end

puts
puts 'done'
