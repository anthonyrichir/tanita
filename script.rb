require 'google_drive'
require 'json'

path_to_data_file = '/Volumes/NO NAME/TANITA/GRAPHV1/DATA/DATA1.CSV'
path_to_utils_file = 'utils.json'
date_format = "%d/%m/%Y"

keywords = {
  'date' => 'DT',
  'time' => 'Ti',
  'gender' => 'GE',
  'age' => 'AG',
  'height' => 'Hm',
  'activity' => 'AL',
  'weight' => 'Wk',
  'bmi' => 'MI',
  'fat' => 'FW',
  'fat_rarm' => 'Fr',
  'fat_larm' => 'Fl',
  'fat_rleg' => 'FR',
  'fat_lleg' => 'FL',
  'fat_trunk' => 'FT',
  'muscle' => 'mW',
  'muscle_rarm' => 'mr',
  'muscle_larm' => 'ml',
  'muscle_rleg' => 'mR',
  'muscle_lleg' => 'mL',
  'muscle_trunk' => 'mT',
  'bones' => 'bw',
  'visceral' => 'IF',
  'meta_age' => 'rA',
  'water' => 'ww',
}

desired = %w(date time weight bmi fat muscle visceral meta_age water)

puts "Will try to read #{path_to_utils_file}"

utils_file = File.read(path_to_utils_file) if File.file?(path_to_utils_file)
utils = utils_file ? JSON.parse(utils_file) : {}

start_date = utils['lastDate'] ? Date.strptime(utils['lastDate'], date_format) + 1 : Date.new(2016, 8, 17)
puts "Setting start date to #{start_date.strftime(date_format)}"

offset = utils['offset'] ? utils['offset'] + 1 : 2
puts "Setting offset to #{offset}"

puts "Will read from #{path_to_data_file}"

data = []

File.open(path_to_data_file, "r") do |f|
  f.each_line do |line|
    originals = Hash[*line.split(",")]
    prettified = {}

    desired.each { |keyword| prettified[keyword] = originals[keywords[keyword]] }

    # strip date and time field of quotes and escape characters
    prettified['date'] = Date.strptime(prettified['date'].gsub(/\A"|"\Z/, ''), date_format)
    prettified['time'] = prettified['time'].gsub(/\A"|"\Z/, '')

    data << prettified if prettified['date'] >= start_date
  end
end

puts "Data read!"
puts "Connecting to Google Drive!"

session = GoogleDrive::Session.from_config('config.json')

puts "Fetching spreadsheet!"

ws = session.spreadsheet_by_key("1gKTJtf69HuY1KTMdSwiasUZzulkLiSsokPyVLvWLmpE").worksheets[0]

puts "Uploading data!"

(start_date..Date.today).each_with_index do |date, i|
  row_index = i + offset

  row = data.select { |d| d['date'] == date }.first

  pretty_date = date.strftime(date_format)

  utils['lastDate'] = pretty_date
  utils['offset'] = row_index

  ws[row_index, 1] = row_index - 1
  ws[row_index, 2] = pretty_date

  next if row.nil?

  ws[row_index, 3] = row['time']
  ws[row_index, 4] = row['weight']
  ws[row_index, 5] = row['bmi']
  ws[row_index, 6] = row['fat']
  ws[row_index, 7] = row['muscle']
  ws[row_index, 8] = row['visceral']
  ws[row_index, 9] = row['meta_age']
  ws[row_index, 10] = row['water']
end

puts "Saving spreadsheet!"

ws.save

puts "Updating utils file!"

File.open(path_to_utils_file,"w") do |f|
  f.write(JSON.pretty_generate(utils))
end

puts "Done!"
