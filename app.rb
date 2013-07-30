require 'bundler'
Bundler.require

require 'digest'
require 'archive/zip/codec/traditional_encryption'

set :haml, :format => :html5, :layout => :layout

get '/' do
  haml :index
end

post '/upload' do
  hash = Digest::SHA256.file(params['zip-file'][:tempfile]).hexdigest
  dir = File.join('tmp', hash)
  output_dir = File.join(dir, 'output')
  Dir.mkdir(dir) unless Dir.exists?(dir)
  Dir.mkdir(output_dir) unless Dir.exists?(output_dir)

  zip_file = File.join(dir, params['zip-file'][:filename])

  File.open(zip_file, "w") do |file|
    file.write(params['zip-file'][:tempfile].read)
  end

  Archive::Zip.extract(zip_file, output_dir)
  File.unlink(zip_file)

  @password = generate_password

  Archive::Zip.archive(
    zip_file,
    "#{output_dir}/.",
    :encryption_codec => Archive::Zip::Codec::TraditionalEncryption,
    :password => @password
  )

  FileUtils.rm_rf(output_dir)

  @download_link = "download/#{hash}/#{params['zip-file'][:filename]}"

  haml :uploaded
end

get '/download/:hash/:filename' do |hash, filename|
  content_type "application/zip"
  file = File.join("tmp", hash.gsub(/[^a-f0-9]/, ''), filename.gsub('..', ''))
  exit unless File.exists?(file)
  File.read(file)
end

def generate_password
  charset = "abcdefghijklmnopqrstuvwxyz1234567890"
  password = ""
  16.times { password += charset[rand(charset.length)] }

  password
end
