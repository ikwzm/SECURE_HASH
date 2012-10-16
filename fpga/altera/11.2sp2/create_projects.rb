#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#---------------------------------------------------------------------------------
#
#       Version     :   0.7.2
#       Created     :   2012/10/16
#       File name   :   create_projects.rb
#       Author      :   Ichiro Kawazome <ichiro_k@ca2.so-net.ne.jp>
#       Description :   QuartusII$Bmt%#ea%gecNe&/eb%/eb%!eb%Cec0e#rmt^h/peaRe#keb%1eb%Cec%'ecNe%h(B.
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
class ProjectCreater
  def initialize
    @program_name      = "create_projects.rb"
    @program_version   = "0.7.2"
    @program_id        = @program_name + " " + @program_version
    @quartus_version   = "11.1"
    @verbose           = true
    @all               = false
    @device            = Array.new
    @sha_type          = Array.new
    @words             = Array.new
    @block_gap         = Array.new
    @i_width           = Array.new
    @o_width           = Array.new
    @ip_path           = "./ip"
    @device_family     = {"arria2"    => "ArriaII",
                          "cyclone4"  => "Cyclone IV GX"
                         }
    @ip_core_name      = {:sha1       => "sha1_avalon_stream",
                          :sha256     => "sha256_avalon_stream",
                          :sha512     => "sha512_avalon_stream"
                         }
    @opt               = OptionParser.new do |opt|
      opt.program_name = @program_name
      opt.version      = @program_version
      opt.on("--verbose"              ){|val| @verbose   = true    }
      opt.on("--all"                  ){|val| @all       = true    }
      opt.on("--device   DEVICE_NAME" ){|val| @device    << val    }
      opt.on("--sha1"                 ){|val| @sha_type  << :sha1  }
      opt.on("--sha256"               ){|val| @sha_type  << :sha256}
      opt.on("--sha512"               ){|val| @sha_type  << :sha512}
      opt.on("--words     WORDS"      ){|val| @words     << val    }
      opt.on("--block_gap BLOCK_GAP"  ){|val| @block_gap << val    }
      opt.on("--i_width   I_WIDTH"    ){|val| @i_width   << val    }
      opt.on("--o_width   O_WIDTH"    ){|val| @o_width   << val    }
      opt.on("--ip_path   PATH"       ){|val| @ip_path   =  val    }
    end
  end

  #-------------------------------------------------------------------------------
  # create_all
  #-------------------------------------------------------------------------------
  def create_all
    p @device
    device_list    = @device.empty?   ? ["cyclone4", "arria2"]    : @device.uniq
    sha_type_list  = @sha_type.empty? ? [:sha1, :sha256, :sha512] : @sha_type.uniq
    words_list     = @words.empty?    ? [1,2]                     : @words.uniq
    block_gap_list = @block_gap.empty?? [0,1,4]                   : @block_gap.uniq
    ip_path        = Pathname.new(@ip_path)

    device_list.each{|device|
      sha_type_list.each{|sha_type|
         words_list.each{|words|
            block_gap_list = (not @block_gap.empty?) ? @block_gap.uniq :
                             (sha_type == :sha1    ) ? [0,1]           :
                             (words    != 1        ) ? [0,1]           : [0,1,4]
            i_width_list   = (not @i_width.empty?  ) ? @i_width.uniq   :
                             (sha_type == :sha512  ) ? [64]            : [32]
            o_width_list   = (not @o_width.empty?  ) ? @o_width.uniq   : 
                             (sha_type == :sha512  ) ? [64]            : [32]
            block_gap_list.each{|block_gap|
              i_width_list.each{|i_width|
                o_width_list.each{|o_width|
                  create(device, sha_type, words, block_gap, i_width, o_width, ip_path)
                }
              }
            }
         }
       }
    }
  end

  #-------------------------------------------------------------------------------
  # create
  #-------------------------------------------------------------------------------
  def create(device, sha_type, words, block_gap, i_width, o_width, ip_path)
    device_family = @device_family[device]
    ip_core_name  = @ip_core_name[sha_type]
    name = sprintf("%s_w%d_g%d_i%d_o%d", sha_type, words, block_gap, i_width, o_width)
    path = Pathname.new(sprintf("./%s/%s", device, name))
    if (@verbose)
      printf "%s : Create %s\n", @program_id, path
    end
    #-----------------------------------------------------------------------------
    # create project directory
    #-----------------------------------------------------------------------------
    FileUtils.makedirs(path)
    FileUtils.makedirs(path+"ip")
    #-----------------------------------------------------------------------------
    # create name.qpf
    #-----------------------------------------------------------------------------
    File.open(path+sprintf("%s.qpf", name), "w"){|file|
      file.printf("QUARTUS_VERSION  = \"%s\"\n", @quartus_version)
      file.printf("PROJECT_REVISION = \"%s\"\n", name)
    }
    #-----------------------------------------------------------------------------
    # create name.qsf
    #-----------------------------------------------------------------------------
    File.open(path+sprintf("%s.qsf", name), "w"){|file|
      qip_file      = (ip_path + sprintf("%s.qip", sha_type)).relative_path_from(path)
      file.print <<-"END_OF_QSF".gsub(/^\s*/,'')
        set_global_assignment   -name FAMILY "#{device_family}"
        set_global_assignment   -name DEVICE AUTO
        set_global_assignment   -name TOP_LEVEL_ENTITY #{name}
        set_global_assignment   -name QIP_FILE #{name}/synthesis/#{name}.qip
        set_global_assignment   -name QIP_FILE #{qip_file}
        set_global_assignment   -name SDC_FILE #{name}.sdc
        set_global_assignment   -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
        set_global_assignment   -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
        set_global_assignment   -name PARTITION_COLOR 16764057 -section_id Top
        set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top
      END_OF_QSF
    }
    #-----------------------------------------------------------------------------
    # create name.sdc
    #-----------------------------------------------------------------------------
    File.open(path+sprintf("%s.sdc", name), "w"){|file|
      file.print <<-"END_OF_SDC".gsub(/^\s*/,'')
        set_time_format -unit ns -decimal_places 3
        create_clock -name {CLOCK} -period 10.000 -waveform { 0.000 5.000 } [get_ports {clk_clk}]
        set_clock_uncertainty -rise_from [get_clocks {CLOCK}] -rise_to [get_clocks {CLOCK}]  0.020  
        set_clock_uncertainty -rise_from [get_clocks {CLOCK}] -fall_to [get_clocks {CLOCK}]  0.020  
        set_clock_uncertainty -fall_from [get_clocks {CLOCK}] -rise_to [get_clocks {CLOCK}]  0.020  
        set_clock_uncertainty -fall_from [get_clocks {CLOCK}] -fall_to [get_clocks {CLOCK}]  0.020  
      END_OF_SDC
    }
    #-----------------------------------------------------------------------------
    # create name.qsys
    #-----------------------------------------------------------------------------
    File.open(path+sprintf("%s.qsys", name), "w"){|file|
      i_bytes = i_width/8
      o_bytes = o_width/8
      file.print <<-"END_OF_QSYS".gsub(/^        /,'')
        <?xml version="1.0" encoding="UTF-8"?>
        <system name="$${FILENAME}">
         <component
           name="$${FILENAME}"
           displayName="$${FILENAME}"
           version="1.0"
           description=""
           tags=""
           categories="" />
         <parameter name="bonusData"><![CDATA[bonusData 
         {
           element SHA
           {
              datum _sortIndex
              {
                 value = "1";
                 type = "int";
              }
           }
           element CLK
           {
              datum _sortIndex
              {
                 value = "0";
                 type = "int";
              }
           }
         }
        ]]></parameter>
         <parameter name="clockCrossingAdapter" value="HANDSHAKE" />
         <parameter name="device" value="" />
         <parameter name="deviceFamily" value="STINGRAY" />
         <parameter name="deviceSpeedGrade" value="" />
         <parameter name="fabricMode" value="QSYS" />
         <parameter name="generateLegacySim" value="false" />
         <parameter name="generationId" value="0" />
         <parameter name="globalResetBus" value="false" />
         <parameter name="hdlLanguage" value="VERILOG" />
         <parameter name="maxAdditionalLatency" value="1" />
         <parameter name="projectName" value="" />
         <parameter name="sopcBorderPoints" value="false" />
         <parameter name="systemHash" value="1" />
         <parameter name="timeStamp" value="1350128449939" />
         <parameter name="useTestBenchNamingPattern" value="false" />
         <instanceScript></instanceScript>
         <interface name="clk"   internal="CLK.clk_in" type="clock" dir="end" />
         <interface name="reset" internal="CLK.clk_in_reset" type="reset" dir="end" />
         <interface name="i"     internal="SHA.in"  type="avalon_streaming" dir="end" />
         <interface name="o"     internal="SHA.out" type="avalon_streaming" dir="start" />
         <module kind="clock_source" version="#{@quartus_version}" enabled="1" name="CLK">
          <parameter name="clockFrequency" value="50000000" />
          <parameter name="clockFrequencyKnown" value="true" />
          <parameter name="inputClockFrequency" value="0" />
          <parameter name="resetSynchronousEdges" value="NONE" />
         </module>
         <module kind="#{ip_core_name}" version="#{@quartus_version}" enabled="1" name="SHA">
          <parameter name="I_BYTES"   value="#{i_bytes}" />
          <parameter name="O_BYTES"   value="#{o_bytes}" />
          <parameter name="WORDS"     value="#{words}" />
          <parameter name="BLOCK_GAP" value="#{block_gap}" />
          <parameter name="AUTO_DEVICE_FAMILY" value="#{device_family}" />
         </module>
         <connection kind="clock" version="#{@quartus_version}" start="CLK.clk"       end="SHA.clk"       />
         <connection kind="reset" version="#{@quartus_version}" start="CLK.clk_reset" end="SHA.clk_reset" />
        </system>
      END_OF_QSYS
    }
    #-----------------------------------------------------------------------------
    # create ip/sha_type_hw.tcl
    #-----------------------------------------------------------------------------
    new_hw_tcl_path = path + sprintf("ip/%s_hw.tcl", ip_core_name)
    File.open(new_hw_tcl_path, "w"){|file|
      File.open(ip_path + sprintf("%s_hw.tcl", ip_core_name), "r") {|original|
        while text_line = original.gets
          if text_line =~ /TOP_LEVEL_HDL_FILE\s+(\S*)/
            old_file = $1.gsub(/["]/,'')
            new_file = (ip_path + old_file).relative_path_from(new_hw_tcl_path.parent)
            text_line = text_line.gsub(/"\S*.vhd"/, new_file.to_s)
          end
          if text_line =~ /add_file\s+(\S*)\s+/
            old_file = $1.gsub(/["]/,'')
            new_file = (ip_path + old_file).relative_path_from(new_hw_tcl_path.parent)
            text_line = text_line.gsub(/add_file\s+\S*/, "add_file "+new_file.to_s)
          end
          file.print text_line
        end
      }
    }
  end 

  #-------------------------------------------------------------------------------
  # parse_options
  #-------------------------------------------------------------------------------
  def parse_options(argv)
    @opt.parse(argv)
  end

end

project_creater = ProjectCreater.new
project_creater.parse_options(ARGV)
project_creater.create_all
