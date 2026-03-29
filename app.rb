require 'sinatra'
require 'omniauth-hack_club'
require 'dotenv/load'
require 'rest-client'
require 'json'

set :public_folder, __dir__ + '/public

enable :sessions

get '/' do
    send_file 'index.html'
end

get '/auth/hack_club' do 
    client_id= ENV['HACKCLUB_CLIENT_ID']
    redirect_uri = "http://localhost:4567/auth/hack_club/callback"


auth_url = "https://auth.hackclub.com/oauth/authorize?" \
               "client_id=#{client_id}&" \
               "redirect_uri=#{redirect_uri}&" \
               "response_type=code&" \
               "scope=openid%20email%20name"

redirect auth_url
end 

get '/auth/hack_club/callback' do
    code = params[:code]


    token_response = RestClient.post('https://auth.hackclub.com/oauth/token', {
        client_id: ENV['HACKCLUB_CLIENT_ID'],
        client_secret: ENV['HACKCLUB_CLIENT_SECRET'], 
        code: code,
        grant_type: 'authorization_code',
        redirect_uri: "http://localhost:4567/auth/hack_club/callback"
    })


    access_token = JSON.parse(token_response.body)['access_token']

    user_response = RestClient.get('https://auth.hackclub.com/api/v1/me',
    {Authorization: "Bearer #{access_token}" }
    )

    user_data = JSON.parse(user_response.body)

    "heyo #{user_data['name']}! Your logged in"
end 