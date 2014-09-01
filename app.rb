require 'sinatra'
require 'haml'
require 'json'

require './models'

require './controllers/controller_dashboard'

require 'bundler'
Bundler.require

## TODO
## Can't update post using Graph API. Can't publish an unpublished post.

APP_ID = '674084699339685'
APP_SECRET = '21b52dc7ad1a19fc400b765187745ee6'

class Sinatra::Application < Sinatra::Base
	enable :sessions
	set :session_secret, 'as98723kjgkny9afvxcsd8e7*&^*&^(Ydkjas'
	register Sinatra::Flash
end

get '/' do
	# check access
	if session['access_token']
		redirect '/dashboard'
	end

	haml :index
end

get '/auth/login' do
	# login with facebook
	session['oauth'] = Koala::Facebook::OAuth.new(APP_ID, APP_SECRET, "#{request.base_url}/callback")
	redirect session['oauth'].url_for_oauth_code(:permissions => "manage_pages,publish_actions,read_insights")
end

get '/auth/logout' do
	# logout
	session['oauth'] = nil
	session['access_token'] = nil
	redirect '/'
end

get '/callback' do
	# callback after getting token
	session['access_token'] = session['oauth'].get_access_token(params[:code])
	redirect '/'
end