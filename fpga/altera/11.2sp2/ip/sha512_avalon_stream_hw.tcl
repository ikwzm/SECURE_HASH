#--------------------------------------------------------------------------
# Avalon-ST SHA-512 component description
#--------------------------------------------------------------------------

package require -exact sopc 9.1

set_module_property NAME                         sha512_avalon_stream
set_module_property DISPLAY_NAME                 "SHA-512 Generator Avalon-ST Wrapper Module"
set_module_property AUTHOR                       "ikwzm"
set_module_property TOP_LEVEL_HDL_FILE           "../../../../src/examples/vhdl/sha512_avalon_stream.vhd"
set_module_property TOP_LEVEL_HDL_MODULE         sha512_avalon_stream
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property VERSION                      11.1
set_module_property EDITABLE                     false
set_module_property SIMULATION_MODEL_IN_VHDL     true
set_module_property ANALYZE_HDL                  false

add_file "../../../../src/examples/vhdl/sha512_avalon_stream.vhd" {SYNTHESIS SIMULATION}

## --------------------------------------------
#|
#| Module parameters
#|
add_parameter          I_BYTES    INTEGER        4  ""
set_parameter_property I_BYTES    ALLOWED_RANGEs "1 2 4 8 16"
set_parameter_property I_BYTES    DISPLAY_NAME   "Input Bytes per beat"
set_parameter_property I_BYTES    DESCRIPTION    "Input Bytes per beat"
set_parameter_property I_BYTES    HDL_PARAMETER  true 

add_parameter          O_BYTES    INTEGER        4  ""
set_parameter_property O_BYTES    ALLOWED_RANGES "1 2 4 8 16"
set_parameter_property O_BYTES    DISPLAY_NAME   "Output Bytes per beat"
set_parameter_property O_BYTES    DESCRIPTION    "Output Bytes per beat"
set_parameter_property O_BYTES    HDL_PARAMETER  true 

add_parameter          WORDS      INTEGER        1  ""
set_parameter_property WORDS      ALLOWED_RANGES "1 2 4"
set_parameter_property WORDS      DISPLAY_NAME   "Word Size"
set_parameter_property WORDS      DESCRIPTION    "Word Size per one cycle"
set_parameter_property WORDS      HDL_PARAMETER  true 

add_parameter          BLOCK_GAP  INTEGER        1
set_parameter_property BLOCK_GAP  ALLOWED_RANGES "0 1 4"
set_parameter_property BLOCK_GAP  DISPLAY_NAME   "Block Gap Cycle"
set_parameter_property BLOCK_GAP  DESCRIPTION    "Block Gap Cycle"
set_parameter_property BLOCK_GAP  HDL_PARAMETER  true

## --------------------------------------------
#|
#| Callback routines
#|
set_module_property ELABORATION_CALLBACK "elaborate"
set_module_property VALIDATION_CALLBACK  "validate"

proc log2ceil {num} {

    set val 0
    set i 1
    while {$i < $num} {
        set val [expr $val + 1]
        set i [expr 1 << $val]
    }

    return $val;
}

## ---------------------------------
#|
#| 
#| 
#|
proc validate {} {

}

proc elaborate {} {

    set i_bytes       [ get_parameter_value "I_BYTES" ]
    set o_bytes       [ get_parameter_value "O_BYTES" ]
    set i_data_width  [ expr $i_bytes * 8 ]
    set i_empty_width [ log2ceil $i_bytes ]
    set o_data_width  [ expr $o_bytes * 8 ]

    # In clock interface
    add_interface          "clk" "clock"    "end" 
    add_interface_port     "clk" "CLOCK"    "clk"     Input 1
    add_interface_port     "clk" "RESET_N"  "reset_n" Input 1

    # Avalon-ST sink interface
    add_interface          "in"  "avalon_streaming" "sink" "clk"
    set_interface_property "in"  symbolsPerBeat    $i_bytes
    set_interface_property "in"  dataBitsPerSymbol 8
    set_interface_property "in"  readyLatency      0
    set_interface_property "in"  maxChannel        0
    add_interface_port     "in"  "I_DATA"  "data"          Input  $i_data_width
    add_interface_port     "in"  "I_VALID" "valid"         Input  1
    add_interface_port     "in"  "I_READY" "ready"         Output 1
    add_interface_port     "in"  "I_SOP"   "startofpacket" Input  1
    add_interface_port     "in"  "I_EOP"   "endofpacket"   Input  1
    add_interface_port     "in"  "I_EMPTY" "empty"         Input  4

    # Avalon-ST source interface
    add_interface          "out" "avalon_streaming" "source" "clk"
    set_interface_property "out" symbolsPerBeat    $o_bytes
    set_interface_property "out" dataBitsPerSymbol 8
    set_interface_property "out" readyLatency      0
    set_interface_property "out" maxChannel        0
    add_interface_port     "out" "O_DATA"  "data"          Output $o_data_width
    add_interface_port     "out" "O_VALID" "valid"         Output 1
    add_interface_port     "out" "O_READY" "ready"         Input  1
    add_interface_port     "out" "O_SOP"   "startofpacket" Output 1
    add_interface_port     "out" "O_EOP"   "endofpacket"   Output 1
    add_interface_port     "out" "O_EMPTY" "empty"         Output 4
}

