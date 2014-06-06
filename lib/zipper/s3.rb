require "aws/s3"

module Zipper
  class S3
    if ENV['ZIPPER_S3_BUCKET'] && ENV['AWS_ACCESS_KEY_ID'] && ENV['AWS_SECRET_ACCESS_KEY']
      begin
        region = ENV['AWS_REGION'] || "us-west-2"

        AWS.config(
          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
          region: region
        )

        S3 = AWS::S3.new
        BUCKET = S3.buckets[ENV['ZIPPER_S3_BUCKET']]

        def self.store(filename, data)
          BUCKET.objects[filename].write(data)
        end

        def self.find(filename)
          BUCKET.objects[filename]
        end

        def self.enabled?
          true
        end
      rescue
        def self.enabled?
          false
        end
      end
    else
      def self.enabled?
        false
      end
    end
  end
end
