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

	@scheduled = $redis.get('scheduled'+@page_id)

	haml :page
end

post '/publish/:id' do
	page_id = params[:id]
	page_token = params['t']

	page_graph = Koala::Facebook::API.new(page_token)

	begin
		if(params['scheduled_status_time'] != nil && params['scheduled_status_time'] != "")
			res = page_graph.put_connections(page_id, 'feed', :message => params['message'], :link => params['link'], :published => false, :scheduled_publish_time => (params['scheduled_status_time'].to_i + Time.now.to_i) )
		else
			res = page_graph.put_connections(page_id, 'feed', :message => params['message'], :link => params['link'], :published => (not params['unpublished']))
		end
		puts res
	rescue Exception => e
		puts e
	end

	redirect to('/dashboard/' + page_id + "?t=" + page_token)
end

post '/publish_photo/:id' do
	page_id = params[:id]
	page_token = params['t']

	page_graph = Koala::Facebook::API.new(page_token)

	begin
		if(params['scheduled_photo_time'] != nil && params['scheduled_photo_time'] != "")
			res = page_graph.put_picture(params['photo_file'], {:message => params['message'], :published => false, :scheduled_publish_time => (params['scheduled_photo_time'].to_i + Time.now.to_i)})
		else
			res = page_graph.put_picture(params['photo_file'], {:message => params['message'], :published => (not params['unpublished_photo'])})
		end
		puts res
	rescue Exception => e
		puts e
	end

	redirect to('/dashboard/' + page_id + "?t=" + page_token)
end

post '/publish_video/:id' do
	page_id = params[:id]
	page_token = params['t']

	page_graph = Koala::Facebook::API.new(page_token)

	begin
		if(params['scheduled_video_time'] != nil && params['scheduled_video_time'] != "")
			res = page_graph.put_video(params['video_file'], {:description => params['message'], :published => false, :scheduled_publish_time => (params['scheduled_video_time'].to_i + Time.now.to_i)})
		else
			res = page_graph.put_video(params['video_file'], {:description => params['message'], :published => (not params['unpublished_video'])})
		end
		puts res
	rescue Exception => e
		puts e
	end

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

get '/post_stats/:id' do
	@post_id = params[:id]
	page_token = params['t']

	@stats_blue = {}
	@stats_green = {}
	@stats_red = {}

	page_graph = Koala::Facebook::API.new(page_token)

	@stats_blue['Likes'] = page_graph.get_connections(@post_id, 'likes').length
	@stats_blue['Comments'] = page_graph.get_connections(@post_id, 'comments').length
	@stats_blue['Shared Posts'] = page_graph.get_connections(@post_id, 'sharedposts').length

	graph = Koala::Facebook::API.new(session['access_token'])
	@stats_green['Post Impressions'] = graph.get_connections(@post_id, 'insights/post_impressions')[0]['values'][0]['value']
	@stats_green['Post Impressions Unique'] = graph.get_connections(@post_id, 'insights/post_impressions_unique')[0]['values'][0]['value']
	@stats_green['Post Consumptions'] = graph.get_connections(@post_id, 'insights/post_consumptions')[0]['values'][0]['value']
	@stats_green['Post Consumptions Unique'] = graph.get_connections(@post_id, 'insights/post_consumptions_unique')[0]['values'][0]['value']
	@stats_green['Engaged Users'] = graph.get_connection(@post_id, 'insights/post_engaged_users')[0]['values'][0]['value']

	@stats_red['Post Negative Feedback'] = graph.get_connections(@post_id, 'insights/post_negative_feedback')[0]['values'][0]['value']
	@stats_red['Post Negative Feedback Unique'] = graph.get_connections(@post_id, 'insights/post_negative_feedback_unique')[0]['values'][0]['value']

	haml :post_stats
end

get '/page_stats/:id' do
	@page_id = params[:id]
	page_token = params['t']

	@stats_blue = {}
	@stats_green = {}
	@stats_red = {}

	page_graph = Koala::Facebook::API.new(page_token)
	@name = page_graph.get_object('me')['name']

	@stats_blue['Likes'] = page_graph.get_object('me')['likes']
	@stats_blue['Check-ins'] = page_graph.get_object('me')['checkins']
	@stats_blue['Talking About'] = page_graph.get_object('me')['talking_about_count']

	@stats_green['Total Impression (Last 28 Days)'] = page_graph.get_connections(@page_id, 'insights/page_impressions/days_28')[0]['values'].pop['value']
	@stats_green['Total Impression Unique (Last 28 Days)'] = page_graph.get_connections(@page_id, 'insights/page_impressions_unique/days_28')[0]['values'].pop['value']
	@stats_green['Total Consumptions (Last 28 Days)'] = page_graph.get_connections(@page_id, 'insights/page_consumptions/days_28')[0]['values'].pop['value']
	@stats_green['Total Consumptions Unique (Last 28 Days)'] = page_graph.get_connections(@page_id, 'insights/page_consumptions_unique/days_28')[0]['values'].pop['value']
	@stats_green['Total Engaged Users (Last 28 Days)'] = page_graph.get_connections(@page_id, 'insights/page_engaged_users/days_28')[0]['values'].pop['value']

	@stats_red['Total Negative Feedback (Last 28 Days)'] = page_graph.get_connections(@page_id, 'insights/page_negative_feedback/days_28')[0]['values'].pop['value']
	@stats_red['Total Negative Feedback Unique (Last 28 Days)'] = page_graph.get_connections(@page_id, 'insights/page_negative_feedback_unique/days_28')[0]['values'].pop['value']
	
	haml :page_stats
end
