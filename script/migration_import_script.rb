require 'migrator'

Thread.abort_on_exception = true

@start_time = Time.now
puts "----- Starting Import Script at - #{@start_time} -----"

@import_paths = ['/tmp/migrator-1', '/tmp/migrator-2', '/tmp/migrator-3',
                 '/tmp/migrator-4']

# set the right number of mongrels in config/mongrel_cluster.yml
# (e.g. servers: 4) and the starting port (port: 8000)
@bart_urls = {
  '/tmp/migrator-1' => 'admin:test@localhost:8000',
  '/tmp/migrator-2' => 'admin:test@localhost:8001',
  '/tmp/migrator-3' => 'admin:test@localhost:8002',
  '/tmp/migrator-4' => 'admin:test@localhost:8003'
}

@importers = {
  'general_reception.csv'      => ReceptionImporter,
  'update_outcome.csv'         => OutcomeImporter,
  'give_drugs.csv'             => DispensationImporter,
  'art_visit.csv'              => ArtVisitImporter,
  'hiv_first_visit.csv'        => ArtInitialImporter,
  'date_of_art_initiation.csv' => ArtInitialImporter,
  'height_weight.csv'          => VitalsImporter,
  'hiv_staging.csv'            => HivStagingImporter,
  'hiv_reception.csv'          => ReceptionImporter
}

@ordered_files = ['general_reception.csv', 'hiv_reception.csv',
  'hiv_first_visit.csv', 'date_of_art_initiation.csv', 'height_weight.csv',
  'hiv_staging.csv', 'art_visit.csv', 'give_drugs.csv', 'update_outcome.csv'
]

threads = []
#wait_threads = []
#special_case_imports = ['give_drugs.csv','update_outcome.csv']

def import_encounters(afile, import_path)
	puts "-----Starting #{import_path}/#{afile} importing - #{Time.now}"

  importer = @importers[afile].new(import_path)
	importer.create_encounters(afile, @bart_urls[import_path])

	puts "-----#{import_path}/#{afile} imported after #{Time.now - @start_time}s"
end

@import_paths.each do |import_path|
  threads << Thread.new(import_path) do |path|
    @ordered_files.each do |file|
      import_encounters(file, path)
    end
  end
end

=begin
Dir.entries(@import_path).each do |filename|
	next if special_case_imports.include?(filename)
	next unless @file_names.keys.include?(filename)
	threads << Thread.new(filename) do |wrk|
		import_encounters(filename,@importers[filename])
	end
end
threads.each {|thread| thread.join}

special_case_imports.each do |sci|
	wait_threads << Thread.new(sci) do |t|
		import_encounters(sci,@file_names[sci])
	end
end
wait_threads.each {|thread| thread.join}
=end

threads.each {|thread| thread.join}

puts "----- Finished Import Script in #{Time.now - @start_time}s -----"

