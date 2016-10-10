require 'google_drive'

path_to_data_file = '/Volumes/NO NAME/TANITA/GRAPHV1/DATA/DATA1.CSV'
start_date = Date.new(2016, 8, 17)

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

data = []

puts "Will read from #{path_to_data_file}"

File.open(path_to_data_file, "r") do |f|
  f.each_line do |line|
    originals = Hash[*line.split(",")]
    prettified = {}

    desired.each { |keyword| prettified[keyword] = originals[keywords[keyword]] }

    # strip date and time field of quotes and escape characters
    prettified['date'] = prettified['date'].gsub(/\A"|"\Z/, '')
    prettified['time'] = prettified['time'].gsub(/\A"|"\Z/, '')

    data << prettified
  end
end

puts "Data read!"
puts "Connecting to Google Drive!"

session = GoogleDrive::Session.from_config('config.json')

puts "Fetching spreadsheet!"

ws = session.spreadsheet_by_key("1gKTJtf69HuY1KTMdSwiasUZzulkLiSsokPyVLvWLmpE").worksheets[0]

puts "Uploading data!"

(start_date..Date.today).each_with_index do |date, i|
  row_index = i + 2
  pretty_date = date.strftime("%d/%m/%Y")
  row = data.select { |d| d['date'] == pretty_date }.first

  ws[row_index, 1] = row_index - 1

  next if row.nil?

  ws[row_index, 2] = pretty_date
  ws[row_index, 3] = row['time']
  ws[row_index, 4] = row['weight']
  ws[row_index, 5] = row['bmi']
  ws[row_index, 6] = row['fat']
  ws[row_index, 7] = row['muscle']
  ws[row_index, 8] = row['visceral']
  ws[row_index, 9] = row['meta_age']
  ws[row_index, 10] = row['water']
end

puts "Saving!"

ws.save

puts "Done!"
