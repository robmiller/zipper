require 'bundler/setup'

require 'dotenv'
Dotenv.load

require 'sinatra'
require 'haml'

require_relative "helpers/raven"

require_relative "lib/zipper"

set :haml, :format => :html5, :layout => :layout

helpers Helpers

get '/' do
  haml :index
end

post '/upload' do
  begin
    uploader = Zipper::Uploader.new(params['zip-file'])
    uploader.process
  rescue Zipper::ZipperError => e
    @error_message = e.message
    return haml :error
  end

  @password = uploader.password
  @download_link = uploader.download_link

  haml :uploaded
end

get '/download/:hash/:filename' do |hash, filename|
  downloader = Zipper::Downloader.new(hash, filename)

  begin
    content_type "application/zip"
    File.read(downloader.filename)
  rescue
    haml :error
  end
end

error do
  capture_exception env['sinatra.error'], env
  { message: env['sinatra.error'].message }.to_json
end
