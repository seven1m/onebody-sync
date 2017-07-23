require 'bundler'
Bundler.require

DATA_PATH = ARGV.first

Dir[File.join(DATA_PATH, '*.DBF')].each do |path|
  puts
  puts '-' * 10
  p path
  DBF::Table.new(path).each do |rec|
    p rec.attributes
  end
end
