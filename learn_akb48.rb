require 'bundler'
Bundler.setup
require 'face'
require 'open-uri'
require 'pp'

config = YAML.load(open(File.expand_path('config/config.yml', File.dirname(__FILE__))))
client = Face.get_client(
  :api_key    => config['face_com']['api_key'],
  :api_secret => config['face_com']['api_secret'],
)

members = open('http://www.akb48.co.jp/about/members/').reduce([]) do |sum, line|
  if line =~ %r{name=([^"]+)"><img src="([^"]+)"[^>]*alt="([^"]+)"[^>]*>}
    sum.push [$1, $2, $3]
  else
    sum
  end
end

members.each do |member|
  uid, url, name = member
  result =  client.faces_detect(:urls => url, :detector => 'Aggressive')
  if result and result['status'] == 'success' and result['photos'][0]['tags'][0]['recognizable']
    tag = result['photos'][0]['tags'][0]
    tag_result = client.tags_save(
      :tids  => tag['tid'],
      :uid   => "#{uid}@#{config['face_com']['namespace']}",
      :label => name
    )
    print "#{uid}\t#{name}\t"
    if tag_result['status'] == 'success'
      puts "OK\t#{tag_result['message']}"
    else
      puts "NG\tFailed to tag"
    end
  else
    puts "#{uid}\t#{name}\tNG\tFailed to recognize"
  end
end
