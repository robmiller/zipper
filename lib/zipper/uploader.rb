require 'archive/zip'
require 'digest'
require 'archive/zip/codec/traditional_encryption'

module Zipper
  class InvalidFileTypeError < ZipperError; end

  class Uploader
    def initialize(file)
      @file = file
    end

    def process
      unless @file[:type] == 'application/zip'
        raise InvalidFileTypeError "Files of type #{@file[:type]} aren't allowed"
      end

      make_directories
      store_upload
      extract
      rearchive
      cleanup
    end

    def password
      @password ||= Password.new
    end

    def download_link
      @download_link ||= "download/#{hash}/#{@file[:filename]}"
    end

    private

    def hash
      @hash ||= Digest::SHA256.file(@file[:tempfile]).hexdigest
    end

    def dir
      File.join('tmp', hash)
    end

    def output_dir
      File.join(dir, 'output')
    end

    def zip_file
      File.join(dir, @file[:filename])
    end

    def make_directories
      Dir.mkdir(dir) unless Dir.exists?(dir)
      Dir.mkdir(output_dir) unless Dir.exists?(output_dir)
    end

    def store_upload
      File.open(zip_file, "w") do |file|
        file.write(@file[:tempfile].read)
      end
    end

    def extract
      begin
        Archive::Zip.extract(zip_file, output_dir)
      rescue Zlib::DataError => e
        @error_message = e.message
        return haml :error
      end

      File.unlink(zip_file)
    end

    def rearchive
      Archive::Zip.archive(
        zip_file,
        "#{output_dir}/.",
        :encryption_codec => Archive::Zip::Codec::TraditionalEncryption,
        :password => password.to_s
      )
    end

    def cleanup
      FileUtils.rm_rf(output_dir)
      File.unlink(@file[:tempfile]) if File.exists?(@file[:tempfile])
    end
  end
end

