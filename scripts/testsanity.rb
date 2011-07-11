#!/usr/bin/env ruby

require('rubygems')
require('twitter')
require('twitter/console')

version = Twitter::Version.to_version
puts "Sanity testing #{version}"
config_file = File.join(File.dirname(__FILE__), '..', 'config', 'twitter.yml')
twitter = Twitter::Client.from_config(config_file, 't4ruby')

def expect(n, m, message = 'A potential error')
	puts "WARNING: #{message}:\n\t => #{m} instead of #{n}" unless n.eql?(m)
end

puts "Public timeline sanity check"
timeline = twitter.timeline_for(:public, :include_rts => 1)
count = timeline.size
expect 20, count, "Retrieved the last #{count} statuses from the public timeline"

sleep(5)
puts "Friends timeline sanity check"
timeline = twitter.timeline_for(:friends, :include_rts => 1)
count = timeline.size
expect 20, count, "Retrieved the last #{count} statuses from all my friends' timeline"

sleep(5)
puts "User timeline sanity check"
timeline = twitter.timeline_for(:user, :id => 'mbbx6spp', :count => 5, :include_rts => 1)
count = timeline.size
expect 5, count, "Retrieved the last #{count} statuses from one friend"

sleep(5)
puts "User lookup sanity check"
screen_name = 'mbbx6spp'
user = twitter.user(screen_name, :info)
expect screen_name, user.screen_name, 'Retrieved a different user'

#sleep(5)
#puts "User#friends sanity check"
#friends = twitter.user(screen_name, :friends)
#expect Array, friends.class, 
#	'Did not retrieve an Array of users for #user(..., :friends)'

#sleep(5)
#puts "My user info sanity check"
#followers = twitter.my(:info).followers
#expect Array, followers.class, 
#	'Did not retrieve an Array of users for #my(:followers)'

sleep(5)
puts "Status posting sanity check"
posted_status = twitter.status(:post, "Testing Twitter4R v#{version} - http://twitter4r.rubyforge.org")
timeline = twitter.timeline_for(:me, :count => 1)
expect Twitter::Status, posted_status.class, 'Did not return newly posted status'
expect 1, timeline.size, 'Did not retrieve only last status'
expect Array, timeline.class, 'Did not retrieve an Array'
expect timeline[0], posted_status, 'Did not successfully post new status'

sleep(5)
puts "Status retrieval sanity check"
status = twitter.status(:get, posted_status)
expect posted_status, status, 'Did not get proper status'

sleep(5)
puts "Status deletion sanity check"
deleted_status = twitter.status(:delete, posted_status)
expect posted_status.id, deleted_status.id, 'Did not delete same status'

sleep(5)
puts "Direct messaging sanity check"
text = 'This is a test direct message for sanity test script purposes'
message = twitter.message(:post, text, user)
expect text, message.text, 
	'Did not post expected text'
expect user.screen_name, message.recipient.screen_name, 
	'Did not post to expected recipient'

sleep(5)
puts "Favorites sanity check"
favorites = twitter.favorites
expect 0, favorites.size, 'Did not receive expected number of favorites'

sleep(5)
puts "Add favorite sanity check"
status_id = 381975342
status = twitter.favorite(:add, status_id)
favorites = twitter.favorites
expect 1, favorites.size, 'Did not add favorite'
expect status_id, status.id, 'Did not add correct favorite'

sleep(5)
puts "Remove favorite sanity check"
status = twitter.favorite(:remove, status_id)
favorites = twitter.favorites
expect 0, favorites.size, 'Did not remove favorite'
expect status_id, status.id, 'Did not remove correct favorite'

sleep(5)
puts "Trends locations check"
locations = twitter.trends(:locations)
expect locations.first.class, Twitter::Location, 'Did not retrieve locations correctly'

sleep(5)
puts "Trends retrieval check"
trends = twitter.trends
expect trends.class, Twitter::Trendline, 'Did not retrieve trends correctly'

sleep(5)
puts "Reply check"
supo_timeline = twitter.timeline_for(:user, :id => 'SusanPotter')
supo_last_tweet = supo_timline.first
reply_status = supo_last_tweet.reply("Just sanity replying to you before doing full release of #Twitter4R")
expect reply_status.class, Twitter::Status, 'Did not reply as expected'

sleep(5)
puts "Post with geolocation on check"
geo_status = twitter.status(:post, "Geolocation check before releasing version #{version} of #Twitter4R Ruby bindings library for Twitter REST API",
  :lat => 40.1105556, :long => -88.2072222)
expect geo_status.class, Twitter::Status, 'Did not send geolocation twieet as expected'


