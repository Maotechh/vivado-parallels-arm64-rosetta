set script_dir [file dirname [file normalize [info script]]]
set smoke_dir [file dirname $script_dir]
set work_dir [file normalize [file join $smoke_dir work]]
file delete -force $work_dir
file mkdir $work_dir

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

puts "SMOKE_VERSION [version -short]"
puts "SMOKE_HOST [exec uname -m]"

set part xc7a35tcpg236-1
if {[llength [get_parts $part]] == 0} {
    error "Part $part is not available"
}
mark "part_catalog"

create_project smoke_project $work_dir/smoke_project -part $part -force
set_property target_language Verilog [current_project]

set ip_defs [get_ipdefs -all xilinx.com:ip:clk_wiz:*]
if {[llength $ip_defs] == 0} {
    error "clk_wiz IP definition is not available"
}
mark "ip_catalog"

add_files [file join $smoke_dir src led_counter.v]
add_files -fileset sim_1 [file join $smoke_dir src tb_led_counter.v]
add_files -fileset constrs_1 [file join $smoke_dir src basys3_smoke.xdc]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
mark "project_create"

set_property top tb_led_counter [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral
close_sim
mark "behavioral_sim"

set_property top led_counter [current_fileset]
reset_run synth_1
launch_runs synth_1 -jobs 2
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {
    error "Synthesis failed: [get_property STATUS [get_runs synth_1]]"
}
open_run synth_1
report_utilization -file $work_dir/synth_utilization.rpt
report_timing_summary -file $work_dir/synth_timing.rpt
mark "synthesis"

reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
if {[get_property STATUS [get_runs impl_1]] ne "write_bitstream Complete!"} {
    error "Implementation/bitstream failed: [get_property STATUS [get_runs impl_1]]"
}
open_run impl_1
report_utilization -file $work_dir/impl_utilization.rpt
report_timing_summary -file $work_dir/impl_timing.rpt
require_nonempty "$work_dir/smoke_project/smoke_project.runs/impl_1/*.bit" "bitstream"
mark "implementation_bitstream"

file mkdir [file join $work_dir ip]
create_ip -name clk_wiz -vendor xilinx.com -library ip -version * -module_name smoke_clk_wiz -dir $work_dir/ip
generate_target all [get_ips smoke_clk_wiz]
synth_ip [get_ips smoke_clk_wiz]
mark "ip_create_generate"

puts "SMOKE_ALL_PASS"
exit
