#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------
require 'digest/sha1'
require 'digest/sha2'
require 'yaml'
require 'pp'

class ScenarioGenerater
  def initialize(name, digest)
    @digest = digest
    @name   = name
    @no     = 0
    @bytes  = 16
  end

  def  gen(io, offset, message)
    @no += 1
    digest  = @digest.hexdigest(message)
    io.print "---"
    io.puts
    io.print "- N: SAY : \"", @name, " " , @no, "\""
    io.puts
    io.print "- I: "
    io.puts
    while(message.length > 0) do
      m = message.slice!(0,@bytes-offset)
      offset = 0
      io.print "  - XFER: {DATA:["
      io.print m.unpack("C*").map{ |b| "0x%02X" %b }.join(','), "]"
      if  message.length > 0 then
        io.print "}"
      else
        io.print ",LAST:1}"
      end
      io.puts
    end
    io.print "- O: "
    io.puts
    io.print "  - XFER: {DATA:[", digest.unpack("a2"*(digest.length/2)).map{ |b| "0x"+b }.join(','), "],LAST:1}"
    io.puts
  end
  
  def generate(file_name)
    io = open(file_name, "w")
    io.puts "---"
    gen(io, 0, "abc")
    io.puts "---"
    gen(io, 0, "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq")
    io.puts "---"
    (1..300).each{ |byte_size|
      byte_data = Array.new(byte_size){|i| rand(255)}
      offset    = rand(@bytes-1)
      gen(io, offset, byte_data.pack("C*"))
    }
    io.close
  end
end

sha1_gen   = ScenarioGenerater.new("SHA1"  , Digest::SHA1  )
sha1_gen.generate("sha1_test.snr")

sha256_gen = ScenarioGenerater.new("SHA256", Digest::SHA256)
sha256_gen.generate("sha256_test.snr")

sha512_gen = ScenarioGenerater.new("SHA512", Digest::SHA512)
sha512_gen.generate("sha512_test.snr")
