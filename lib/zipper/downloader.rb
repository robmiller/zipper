module Zipper
  class Downloader
    def initialize(hash, filename)
      @hash = hash
      @filename = filename
    end

    def filename
      File.join("tmp", @hash.gsub(/[^a-f0-9]/, ''), @filename.gsub('..', ''))
    end
  end
end
