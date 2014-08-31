get '/dashboard' do
	@graph = Koala::Facebook::API.new(session['access_token'])
	pages = @graph.get_connections('me', 'accounts') # get all my pages

	@first_name = @graph.get_object('me')['first_name']

	@my_pages = []
	pages.each do |page|
		page_token = page['access_token']
		page_graph = Koala::Facebook::API.new(page_token)
		page_object = page_graph.get_object('me') # get page info

		# check if Cover exists
		if not page_object['cover']
			cover = 'http://placehold.it/720x300'
		else
			cover = page_object['cover']['source']
		end

		id = page['id']
		name = page['name']
		category = page['category']
		likes = page_object['likes']
		talking_about_count = page_object['talking_about_count']
		checkins = page_object['checkins']
		unread_notif_count = page_object['unread_notif_count']

		@my_pages.push({"page_token" => page_token, "cover" => cover, "id" => page['id'], "name" => name, "category" => category, "likes" => likes, "talking_about_count" => talking_about_count, "checkins" => checkins, "unread_notif_count" => unread_notif_count})
	end

	haml :dashboard
end

get '/dashboard/:id' do
	@page_id = params[:id]
	@page_token = params['t']

	page_graph = Koala::Facebook::API.new(@page_token)
	page_object = page_graph.get_object('me') # get page info

	@name = page_object['name']
	@about = page_object['about']
	@likes = page_object['likes']
	@talking_about_count = page_object['talking_about_count']
	@checkins = page_object['checkins']
	@unread_notif_count = page_object['unread_notif_count']

	@posts = page_graph.get_connections('me', 'promotable_posts')

	haml :page
end

post '/publish/:id' do
	page_id = params[:id]
	page_token = params['t']

	page_graph = Koala::Facebook::API.new(page_token)
	page_graph.put_connections(page_id, 'feed', :message => params['message'], :link => params['link'], :published => (not params['unpublished']))

	redirect to('/dashboard/' + page_id + "?t=" + page_token)
end

get '/delete/:id' do
	page_id = params[:id]
	page_token = params['t']
	post_id = params['pid']

	page_graph = Koala::Facebook::API.new(page_token)
	page_graph.delete_object(post_id)

	redirect to('/dashboard/' + page_id + "?t=" + page_token)
end