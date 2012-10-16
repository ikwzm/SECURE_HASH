#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------
#
#       Version     :   0.7.2
#       Created     :   2012/10/16
#       File name   :   generate_ip.rb
#       Author      :   Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
#       Description :   QuartusII ip-generate in all project
#
#---------------------------------------------------------------------------------
#
#       Copyright (C) 2012 Ichiro Kawazome
#       All rights reserved.
# 
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions
#       are met:
# 
#         1. Redistributions of source code must retain the above copyright
#            notice, this list of conditions and the following disclaimer.
# 
#         2. Redistributions in binary form must reproduce the above copyright
#            notice, this list of conditions and the following disclaimer in
#            the documentation and/or other materials provided with the
#            distribution.
# 
#       THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#       "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#       LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#       A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
#       OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#       SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
#       LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#       DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#       THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#       OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
#---------------------------------------------------------------------------------
require 'pathname'
require 'optparse'
require 'fileutils'

ip_generate_command = "g:/altera/11.1sp2/quartus/sopc_builder/bin/ip-generate"

Dir::glob("./**/*.qsys").each {|qsys_file|
  base_name  = File.basename(qsys_file, ".qsys")
  base_dir   = Pathname.new(File.dirname(qsys_file))
  output_dir = base_dir + "#{base_name}/synthesis"
  qip_file   = output_dir + "#{base_name}.qip"
  ip_gen_err_file = base_dir + "ip_gen.err"
  ip_gen_log_file = base_dir + "ip_gen.log"
  command = "#{ip_generate_command} --component-file=#{qsys_file} --file-set=QUARTUS_SYNTH --report-file=qip:#{qip_file} --output-directory=#{output_dir} 2> #{ip_gen_err_file} >  #{ip_gen_log_file}"
  puts command
  system(command)
}

