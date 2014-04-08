module Zipper
  class Password
    def initialize
      generate_password
    end

    def to_s
      @password
    end

    private

    def generate_password
      charset = "abcdefghijklmnopqrstuvwxyz"
      password = ""
      6.times { password += charset[rand(charset.length)] }

      @password = password
    end
  end
end
