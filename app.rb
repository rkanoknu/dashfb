require 'sinatra'
require 'haml'
require 'json'
require 'net/http'
require 'nokogiri'
require 'rufus-scheduler'

require './models'

require './controllers/controller_dashboard'

require 'bundler'
Bundler.require

## TODO
## Can't update post using Graph API. Can't publish an unpublished post.

APP_ID = '674084699339685'
APP_SECRET = '21b52dc7ad1a19fc400b765187745ee6'

scheduler = Rufus::Scheduler.new

reddit_var = ""

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

get '/scrape_reddit/:id' do
	page_id = params[:id]
	page_token = params['t']

	if not session['scheduled'+page_id]
		puts "starting schedule"
		session['scheduled'+page_id] = true

		scheduler.every '1m' do
			puts "scraping reddit" + Time.now.to_s
			page_graph = Koala::Facebook::API.new(page_token)

			result = Net::HTTP.get(URI.parse('http://www.reddit.com/.json'))
			doc = JSON.parse(result)
			top = doc['data']['children'][0]['data']

			puts "current vs top id: " + reddit_var + " vs " + top['id']

			if reddit_var != top['id']
				puts "posting reddit"
				puts top['id']
				puts top['title']
				puts "http://www.reddit.com"+top['permalink']

				reddit_var = top['id']

				message = "Post was created on " + (Time.at(top['created'].to_i)).to_s + " by " + top['author'] + " with a score of " + top['score'].to_s + " and with " + top['num_comments'].to_s + " comments."
				puts message

				begin
					page_graph.put_connections(page_id, 'feed', :message => message, :published => false)

					page_graph.put_connections(page_id, 'feed', :message => top['title'], :link => ("http://www.reddit.com"+top['permalink']), :published => true)
				rescue Exception => e
					puts e
				end
			else
				puts "reddit top post has not changed."
			end
		end
	else
		puts "stopping schedule"
		scheduler.every_jobs.each(&:unschedule)
		session['scheduled'+page_id] = false
	end

	redirect to('/dashboard/' + page_id + "?t=" + page_token)
end