#
# create_project.tcl  Tcl script for creating project
#
if {[info exists sha_type         ] == 0} {
    puts "ERROR: Please set sha_type."
    return 1
}
if {[info exists project_name     ] == 0} {
    set project_name        "project"
}
if {[info exists project_directory] == 0} {
    set project_directory   [pwd]
}
if {[info exists source_directory] == 0} {
    set source_directory    [file join [file dirname [info script]] ".." ".." ".." ".." "src"]
}
#
# Create Project
#
create_project -force $project_name $project_directory
#
# Set project properties
#
if       {[info exists board_part ] && [string equal $board_part  "" ] == 0} {
    set_property "board_part"     $board_part      [current_project]
} elseif {[info exists device_part] && [string equal $device_part "" ] == 0} {
    set_property "part"           $device_part     [current_project]
} else {
    puts "ERROR: Please set board_part or device_part."
    return 1
}
set_property "default_lib"        "xil_defaultlib" [current_project]
set_property "simulator_language" "Mixed"          [current_project]
set_property "target_language"    "VHDL"           [current_project]
#
# Create fileset "sources_1"
#
if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
}
#
# Create fileset "constrs_1"
#
if {[string equal [get_filesets -quiet constrs_1] ""]} {
    create_fileset -constrset constrs_1
}
#
# Create fileset "sim_1"
#
if {[string equal [get_filesets -quiet sim_1] ""]} {
    create_fileset -simset sim_1
}
#
# Create run "synth_1" and set property
#
set synth_1_flow     "Vivado Synthesis 2017"
set synth_1_strategy "Vivado Synthesis Defaults"
if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run -name synth_1 -flow $synth_1_flow -strategy $synth_1_strategy -constrset constrs_1
} else {
    set_property flow     $synth_1_flow     [get_runs synth_1]
    set_property strategy $synth_1_strategy [get_runs synth_1]
}
current_run -synthesis [get_runs synth_1]
#
# Create run "impl_1" and set property
#
set impl_1_flow      "Vivado Implementation 2017"
set impl_1_strategy  "Vivado Implementation Defaults"
if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run -name impl_1 -flow $impl_1_flow -strategy $impl_1_strategy -constrset constrs_1 -parent_run synth_1
} else {
    set_property flow     $impl_1_flow      [get_runs impl_1]
    set_property strategy $impl_1_strategy  [get_runs impl_1]
}
current_run -implementation [get_runs impl_1]
#
# Set IP Repository
#
if {[info exists ip_repo_path_list] && [llength $ip_repo_path_list] > 0 } {
    set_property ip_repo_paths $ip_repo_path_list [current_fileset]
    update_ip_catalog
}
#
# Import Constraint files
#
if {[info exists constrs_file_list] && [llength $constrs_file_list] > 0 } {
    add_files    -fileset constrs_1 -norecurse $constrs_file_list
}
#
# Add VHDL Files
#
proc add_vhdl_file {fileset_name library_name file_name} {
    set file    [file normalize $file_name]
    set fileset [get_filesets   $fileset_name] 
    add_files -norecurse -fileset $fileset $file
    set file_obj [get_files -of_objects $fileset $file]
    set_property "file_type" "VHDL"        $file_obj
    set_property "library"   $library_name $file_obj
}
add_vhdl_file sources_1     "IKWZM_SECURE_HASH" [file join $source_directory "main"     "vhdl" "sha_pre_proc.vhd"]
add_vhdl_file sources_1     "IKWZM_SECURE_HASH" [file join $source_directory "main"     "vhdl" "sha_schedule.vhd"]
add_vhdl_file sources_1     "IKWZM_SECURE_HASH" [file join $source_directory "main"     "vhdl" "reducer.vhd"     ]
add_vhdl_file sources_1     "IKWZM_SECURE_HASH" [file join $source_directory "main"     "vhdl" [join [list $sha_type ".vhd"              ] ""]]
if {[string compare $sha_type "sha1"] == 0} {
    add_vhdl_file sources_1 "IKWZM_SECURE_HASH" [file join $source_directory "main"     "vhdl" [join [list $sha_type "_proc.vhd"         ] ""]]
} else {
    add_vhdl_file sources_1 "IKWZM_SECURE_HASH" [file join $source_directory "main"     "vhdl" [join [list $sha_type "_k_table.vhd"      ] ""]]
    add_vhdl_file sources_1 "IKWZM_SECURE_HASH" [file join $source_directory "main"     "vhdl" [join [list $sha_type "_proc_simple.vhd"  ] ""]]
    add_vhdl_file sources_1 "IKWZM_SECURE_HASH" [file join $source_directory "main"     "vhdl" [join [list $sha_type "_proc_pipeline.vhd"] ""]]
}
add_vhdl_file sources_1     "IKWZM_SECURE_HASH" [file join $source_directory "main"     "vhdl" [join [list $sha_type "_core.vhd"         ] ""]]
add_vhdl_file sources_1     "WORK"              [file join $source_directory "examples" "vhdl" [join [list $sha_type "_axi4_stream.vhd"  ] ""]]
#
# Set Generic Parameter
#
lappend generic_list [join [list "I_BYTES="   $sha_i_bytes  ] ""]
lappend generic_list [join [list "O_BYTES="   $sha_o_bytes  ] ""]
lappend generic_list [join [list "WORDS="     $sha_words    ] ""]
lappend generic_list [join [list "BLOCK_GAP=" $sha_block_gap] ""]

set_property generic [join $generic_list " "] [current_fileset]
#
# Close Project
#
close_project
