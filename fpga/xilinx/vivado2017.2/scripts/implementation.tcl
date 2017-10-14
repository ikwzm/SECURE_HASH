#
# implementation.tcl  Tcl script for implementation
#
if {[info exists project_name     ] == 0} {
    set project_name        "project"
}
if {[info exists project_directory] == 0} {
    set project_directory   [pwd]
}

open_project [file join $project_directory $project_name]

launch_runs synth_1
wait_on_run synth_1

launch_runs impl_1
wait_on_run impl_1

open_run    impl_1
report_utilization -file [file join $project_directory [join [list $project_name ".rpt"] ""]]
report_timing      -file [file join $project_directory [join [list $project_name ".rpt"] ""]] -append

close_project

