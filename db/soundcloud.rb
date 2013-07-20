#!/usr/bin/env ruby

require 'soundcloud'
require 'sqlite3'

$client = Soundcloud.new(:client_id => '')
$db = SQLite3::Database.new "azeros.db"
$allTracks = []
$tracksLimit = 200
$nRequests = 200
$rapGenres = ['dirty south', 'hip hop', 'hip-hop', 'hiphop', 'r&b', 'rap']

# Create the database
def createDB()
  rows = $db.execute(" create table tracks (id INTEGER PRIMARY KEY, created_at TEXT, title TEXT, permalink_url TEXT, uri TEXT, genre TEXT, comment_count INTEGER, download_count INTEGER, playback_count INTEGER, favoritings_count INTEGER, shared_to_count INTEGER, raw BLOB);")
end

# Load API data
def downloadTracks(date)

  i = 0
  while i < $nRequests
    tracks = $client.get('/tracks', :genre => 'rap', :'created_at[from]' => "#{date} 00:00:00", :'created_at[to]' => "#{date} 23:59:59", :limit => $tracksLimit, :offset => i*$tracksLimit)

    $allTracks += tracks

  	if tracks.count < 200  then
  		break
  	end

    i += 1
  end
end

# Insert into the database
def insertDB()
  $allTracks.each do |track|
		if track.embeddable_by == "all" and not track.genre.nil? then

		  isRap = false
		  i = 0

			while i < $rapGenres.count
				if track.genre.downcase.include? $rapGenres[i] or 
				   track.title.downcase.include? $rapGenres[i] or
					 track.user.username.downcase.include? $rapGenres[i] then
				  isRap = true
				  break
				else
		      i += 1
				end
			end	

		  if isRap then
		    begin
          $db.execute("INSERT INTO tracks (id, created_at, title, permalink_url, uri, genre, comment_count, download_count, playback_count, favoritings_count, shared_to_count, raw) VALUES (?,?,?,?,?,?,?,?,?,?,?,?); COMMIT;", track.id, ARGV[0], track.title, track.permalink_url, track.uri, track.genre, track.comment_count, track.download_count, track.playback_count, track.favoritings_count, track.shared_to_count, track.to_json)
		    rescue
		      puts "Error while inserting track #{track.id} => #{track.to_json}"
		    end
		  end
		end
  end
end

if ARGV[0] then
	if ARGV[1] == "db" then
		puts "-> Creating the database"
		createDB()
	end

  puts "-> Requesting for the date #{ARGV[0]}"
  downloadTracks(ARGV[0])

  id = $allTracks.map {|t| t.id}
  puts "   Total tracks : #{$allTracks.count}"
  puts "   Total unique tracks : #{id.uniq.count}"
  puts "-> Inserting into the database"
	insertDB()

end
