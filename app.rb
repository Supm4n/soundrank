require 'sinatra/base'
require 'soundcloud'
require 'sqlite3'

$CLIENT_ID = 'fa7686b57cf116d0a2102ad531356005'
$DB = 'db/azeros.db'

class MyApp < Sinatra::Base
#  enable :sessions
  require './helpers'

  get '/' do 
    client = Soundcloud.new(:client_id => $CLIENT_ID)
    db = SQLite3::Database.new $DB
		tracks = db.execute "select permalink_url from tracks order by created_at, playback_count DESC LIMIT 10;"
		
		i = 0
		tracks_html = []
		while i < tracks.count 
		  response = client.get('/oembed', :url => tracks[i][0])
		  tracks_html << response['html']
			i += 1
	  end

  	erb :index, :locals => {:tracks => tracks_html}
  end

  run! if app_file == $0
end
