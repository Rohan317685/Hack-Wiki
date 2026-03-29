require 'sinatra'
require 'omniauth-hack_club'
require 'dotenv/load'

set :bind, '0.0.0.0'
set :port, 4567

set :sessions, true
set :session_secret, 'ioh1udg827tgi7yuagbcyuydnga8t8xgy1xc2ydtba76t9cv7ntg8ng2uy4efbc76nec8waiugbdvuagvw'

use OmniAuth::Builder do 
    provider :hack_club, ENV["HACKCLUB_CLIENT_ID"], ENV["HACKCLUB_CLIENT_SECRET"],
    scope: "openid email name"
end


get '/' do
    send_file 'index.html'
end 

get '/auth/hack_club/callback' do
    auth = request.env['omniauth.auth']
    "Hello #{auth['info']['name']}! Your logged in!"
end 

get '/auth/failure' do
    "Login failed! Message: #{params[:message]}"
end 
