require 'sinatra'
require 'omniauth-hack_club'
require 'dotenv/load'


get '/' do
    send_file 'index.html'
end 

use OmniAuth::Builder do 
    provider :hack_club, ENV["HACKCLUB_CLIENT_ID"], ENV["HACKCLUB_CLIENT_SECRET"]
end

get 'auth/hack_club/callback' do
    "Your logged in!"
end 