if {[llength $argv] > 0} {
    set safe_part [lindex $argv 0]
} else {
    set safe_part xc7a200tsbg484-1
}

set script_dir [file dirname [file normalize [info script]]]
set smoke_dir [file dirname $script_dir]
set work_dir [file normalize [file join $smoke_dir hw_program_work]]
set bit_dir [file normalize [file join $work_dir bit]]

proc mark {name} {
    puts "SMOKE_STEP_PASS $name"
}

proc require_nonempty {glob_pattern label} {
    set matches [glob -nocomplain $glob_pattern]
    if {[llength $matches] == 0} {
        error "Missing expected output for $label: $glob_pattern"
    }
    return [lindex $matches 0]
}

file delete -force $work_dir
file mkdir $bit_dir

puts "SMOKE_VERSION [version -short]"
puts "SMOKE_SAFE_PART $safe_part"

if {[llength [get_parts $safe_part]] == 0} {
    error "Part $safe_part is not available"
}
mark "safe_part_catalog"

read_verilog [file join $smoke_dir src jtag_safe_top.v]
synth_design -top jtag_safe_top -part $safe_part
mark "safe_synth"

opt_design
place_design
route_design
mark "safe_implementation"

report_utilization -file [file join $work_dir safe_utilization.rpt]
report_timing_summary -file [file join $work_dir safe_timing.rpt]

set bit_file [file join $bit_dir jtag_safe_top.bit]
write_bitstream -force $bit_file
require_nonempty $bit_file "safe bitstream"
puts "SMOKE_SAFE_BIT $bit_file"
mark "safe_bitstream"

puts "SMOKE_ALL_PASS_SAFE_BITSTREAM"
exit
