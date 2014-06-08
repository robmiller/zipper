require 'digest'
require 'escape'

require 'pry'

module Zipper
  class InvalidFileTypeError < ZipperError; end
  class ExtractionError < ZipperError; end
  class CompressionError < ZipperError; end

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

      if S3.enabled?
        upload_to_s3
      end

      cleanup
    end

    def password
      @password ||= Password.new
    end

    def download_link
      @download_link ||= if S3.enabled?
                           S3.find(File.basename(zip_file)).url_for(:get, expires: Time.now + 86400, secure: true).to_s
                         else
                           "download/#{hash}/#{@file[:filename]}"
                         end
    end

    private

    def hash
      @hash ||= Digest::SHA256.file(@file[:tempfile]).hexdigest
    end

    def dir
      File.join(Dir.pwd, 'tmp', hash)
    end

    def output_dir
      File.join(dir, 'output')
    end

    def zip_file
      @zip_file ||= File.join(dir, @file[:filename].gsub(/\.\.|\//, ''))
    end

    def make_directories
      [dir, output_dir].each do |d|
        FileUtils.rm_rf(d) if File.exist?(d)
        FileUtils.mkdir_p(d)
      end
    end

    def store_upload
      File.open(zip_file, "w") do |file|
        file.write(@file[:tempfile].read)
      end
    end

    def extract
      system(p Escape.shell_command(["unzip", "#{zip_file}", "-d", "#{output_dir}/"]))
      if $?.exitstatus != 0
        fail ExtractionError.new("I couldn't extract the zip file. Are you sure it's valid? Try testing on your local machine.")
      end

      File.unlink(zip_file)
    end

    def rearchive
      system(Escape.shell_command(["cd", output_dir]) + " && " + Escape.shell_command(["zip", "-r", "-P", password.to_s, zip_file]) + " *")
      if $?.exitstatus != 0
        fail CompressionError.new("I couldn't create the passworded zip file for some reason.")
      end

      true
    end

    def upload_to_s3
      S3.store(File.basename(zip_file), open(zip_file))
    end

    def cleanup
      if S3.enabled?
        FileUtils.rm_rf(dir)
      else
        FileUtils.rm_rf(output_dir)
      end

      File.unlink(@file[:tempfile]) if File.exists?(@file[:tempfile])
    end
  end
end

