require 'sinatra/base'
require 'socket'
require 'yaml'
require 'json'
require 'slim'
require 'compass'

class App < Sinatra::Base
  enable :session
  set :mpd_settings, YAML.load_file('mpd.yml')
  set :mpd, TCPSocket.new(mpd_settings[:host], mpd_settings[:port])
  set :forbidden, %w[idle close kill password]

  Compass.configuration do |c|
    c.sass_dir = views
  end

  set :sass, Compass.sass_engine_options

  puts mpd.gets
  if mpd_settings[:password]
    mpd.puts "password #{mpd_settings[:password].inspect}"
    puts mpd.gets
  end

  get '/' do
    slim :player
  end

  get '/player.js' do
    coffee :player
  end

  get '/player.css' do
    sass :player
  end

  get '/:cmd' do
    pass if params[:cmd] == 'favicon.ico'
    exec params[:cmd]
  end

  get '/:cmd/*' do
    pass if params[:cmd] == '__sinatra__'
    exec params[:cmd], params[:splat].first.split('/')
  end

  def exec(*a)
    content_type :json
    settings.exec(*a)
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
