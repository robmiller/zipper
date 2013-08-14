require 'bundler'
Bundler.require

require 'digest'
require 'archive/zip/codec/traditional_encryption'

set :haml, :format => :html5, :layout => :layout

get '/' do
  haml :index
end

post '/upload' do
  return haml :error unless params['zip-file'][:type] == 'application/zip'

  hash = Digest::SHA256.file(params['zip-file'][:tempfile]).hexdigest
  dir = File.join('tmp', hash)
  output_dir = File.join(dir, 'output')
  Dir.mkdir(dir) unless Dir.exists?(dir)
  Dir.mkdir(output_dir) unless Dir.exists?(output_dir)

  zip_file = File.join(dir, params['zip-file'][:filename])

  File.open(zip_file, "w") do |file|
    file.write(params['zip-file'][:tempfile].read)
  end

  begin
    Archive::Zip.extract(zip_file, output_dir)
  rescue Zlib::DataError => e
    @error_message = e.message
    return haml :error
  end

  File.unlink(zip_file)

  @password = generate_password

  Archive::Zip.archive(
    zip_file,
    "#{output_dir}/.",
    :encryption_codec => Archive::Zip::Codec::TraditionalEncryption,
    :password => @password
  )

  FileUtils.rm_rf(output_dir)
  File.unlink(params['zip-file'][:tempfile]) if File.exists?(params['zip-file'][:tempfile])

  @download_link = "download/#{hash}/#{params['zip-file'][:filename]}"

  haml :uploaded
end

get '/download/:hash/:filename' do |hash, filename|
  file = File.join("tmp", hash.gsub(/[^a-f0-9]/, ''), filename.gsub('..', ''))

  return haml :error unless File.exists?(file)

  content_type "application/zip"
  File.read(file)
end

def generate_password
  charset = "abcdefghijklmnopqrstuvwxyz"
  password = ""
  6.times { password += charset[rand(charset.length)] }

  password
end
