require 'redis'
#require 'data_mapper'

configure :production do
	uri = URI.parse(ENV["REDISCLOUD_URL"])
	$redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)
	#DataMapper.setup(:default, ENV['DATABASE_URL'])
end
configure :development do
	$redis = Redis.new
	#DataMapper.setup(:default, "sqlite://#{Dir.pwd}/db.sqlite")
end
configure :test do
	$redis = Redis.new
	#DataMapper.setup(:default, "sqlite://#{Dir.pwd}/db.sqlite")
end