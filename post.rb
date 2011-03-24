#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# vim: filetype=ruby
require 'rubygems'
require 'oauth'
require 'rubytter'
require 'highline'

abort "usage: #{File.basename(__FILE__)} tokenfile post" if ARGV.size < 2

#oauth-patch.rb http://d.hatena.ne.jp/shibason/20090802/1249204953
if RUBY_VERSION >= '1.9.0'
  module OAuth
    module Helper
      def escape(value)
        begin
          URI::escape(value.to_s, OAuth::RESERVED_CHARACTERS)
        rescue ArgumentError
          URI::escape(
            value.to_s.force_encoding(Encoding::UTF_8),
            OAuth::RESERVED_CHARACTERS
          )
        end
      end
    end
  end

  module HMAC
    class Base
      def set_key(key)
        key = @algorithm.digest(key) if key.size > @block_size
        key_xor_ipad = Array.new(@block_size, 0x36)
        key_xor_opad = Array.new(@block_size, 0x5c)
        key.bytes.each_with_index do |value, index|
          key_xor_ipad[index] ^= value
          key_xor_opad[index] ^= value
        end
        @key_xor_ipad = key_xor_ipad.pack('c*')
        @key_xor_opad = key_xor_opad.pack('c*')
        @md = @algorithm.new
        @initialized = true
      end
    end
  end
end

CONSUMER = {
  :key => "REPLACEME",
  :secret => "REPLACEME"
}
site = "http://api.twitter.com" 
cons = OAuth::Consumer.new(CONSUMER[:key],CONSUMER[:secret], :site => site)


unless File.exist?(ARGV[0])
   request_token = cons.get_request_token
   puts "Access This URL and press 'Allow' => #{request_token.authorize_url}"
   pin = HighLine.new.ask('Input key shown by twitter: ')
   access_token = request_token.get_access_token(
     :oauth_verifier => pin
   )
   open(ARGV[0],"w") do |f|
     f.puts access_token.token
     f.puts access_token.secret
   end
end

keys = File.read(ARGV[0]).split(/\r?\n/).map(&:chomp)

token = OAuth::AccessToken.new(cons, keys[0], keys[1])

t = OAuthRubytter.new(token)

puts ARGV[1]
t.update(ARGV[1])


