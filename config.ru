require 'sinatra/base'
require 'socket'
require 'yaml'
require 'json'
require 'slim'

class App < Sinatra::Base
  enable :session
  set :mpd_settings, YAML.load_file('mpd.yml')
  set :mpd, TCPSocket.new(mpd_settings[:host], mpd_settings[:port])
  set :forbidden, %w[idle close kill password]

  puts mpd.gets
  if mpd_settings[:password]
    mpd.puts "password #{mpd_settings[:password].inspect}"
    puts mpd.gets
  end

  before do
    content_type :json
    request.path_info = request.path_info.gsub /\.([^.]+)$/ do |fmt|
      content_type fmt
      ''
    end
  end

  get '/' do
    content_type :html
    slim :player
  end

  get '/player' do
    coffee :player
  end

  get '/:cmd' do
    settings.exec params[:cmd]
  end

  get '/:cmd/*' do
    pass if params[:cmd] == '__sinatra__'
    settings.exec params[:cmd], params[:splat].first.split('/')
  end

  def self.exec(cmd, *args)
    return {'error' => 'command forbidden'}.to_json if settings.forbidden.include? cmd
    args.flatten!
    args.map! { |a| String === a ? a.inspect : a.to_s }
    line = [cmd.to_s, *args].join " "
    line.gsub! /[\n\r]/, ''
    puts "MPD <<< #{line}"
    mpd.puts line
    read.to_json
  end

  def self.read(all = [], last = nil)
    line = mpd.gets
    puts "MPD >>> #{line}"
    if line.start_with? "ACK "
      [{'error' => line[4..-1]}]
    elsif line =~ /\AOK/
      all
    else
      key, value = line.split ": ", 2
      if last.nil? or last.include? key
        last = {}
        all << last
      end
      last[key] = value.strip
      read all, last
    end
  end
end

run App
