module Zipper
  class ZipperError < Exception; end
end

require_relative "zipper/password"
require_relative "zipper/uploader"
require_relative "zipper/downloader"
