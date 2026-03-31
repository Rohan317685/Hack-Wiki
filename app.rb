require 'sinatra'
require 'omniauth-hack_club'
require 'dotenv/load'
require 'rest-client'
require 'json'

set :public_folder, __dir__ + '/public'
set :static_cache_control, [:no_cache, :must_revalidate, :max_age => 0]
enable :sessions

get '/' do
    send_file File.join(settings.public_folder, 'index.html')
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

    session[:user_data] = user_data

    "Logged in! <a href='/admin/scan'>Click here to start the scan</a>"
end 

def fetch_shipped_repos

    url = "https://ships.hackclub.com/api/v1/projects"

    response = RestClient.get(url, {
        Authorization: "Bearer #{ENV['UNIFIED_DB_API_KEY']}"
    })

    JSON.parse(response.body)
end 

get '/admin/scan' do
 
  redirect '/auth/hack_club' unless session[:user_data]


  projects = fetch_shipped_repos
  results = []

  projects.each do |project|
    repo_url = project.dig('fields', 'repo_url') || project.dig('fields', 'repository') || project['repo_url']
    next unless repo_url&.include?("github.com")

    begin

      api_url = repo_url.gsub("github.com", "api.github.com/repos")

      RestClient.get(api_url, {
                "User-Agent" => "Hack-Club-Repo-Checker",
                "Authorization" => "token #{ENV['GITHUB_TOKEN']}"
            })

      status = "Public"
    rescue RestClient::NotFound
      status = "PRIVATE/DELETED"

    rescue => e
      status = "Error: #{e.message}"
    end

    results << { name: project['name'], status: status, url: repo_url }

    sleep 0.05
  end


  content_type :json
  results.to_json
end

