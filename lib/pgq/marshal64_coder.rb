require 'base64'

module Pgq::Marshal64Coder

  def self.dump(s)
    Base64::encode64(Marshal.dump(s))
  end

  def self.load(s)
    Marshal.load(Base64::decode64(s))
  end

end