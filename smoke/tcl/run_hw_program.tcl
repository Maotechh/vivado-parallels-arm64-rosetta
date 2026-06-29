if {[llength $argv] < 1 || [llength $argv] > 2} {
    error "Usage: vivado -mode batch -source run_hw_program.tcl -tclargs <bit_file> ?hw_part?"
}

set bit_file [file normalize [lindex $argv 0]]
set expected_part xc7a200t
if {[llength $argv] == 2} {
    set expected_part [lindex $argv 1]
}

if {![file exists $bit_file]} {
    error "Bitstream does not exist: $bit_file"
}

puts "SMOKE_VERSION [version -short]"
puts "SMOKE_PROGRAM_BIT $bit_file"
puts "SMOKE_EXPECTED_HW_PART $expected_part"

open_hw_manager
connect_hw_server -url localhost:3121
puts "SMOKE_STEP_PASS connect_hw_server"

set targets [get_hw_targets *]
puts "SMOKE_HW_TARGET_COUNT [llength $targets]"
foreach target $targets {
    puts "SMOKE_HW_TARGET [get_property NAME $target]"
}
if {[llength $targets] == 0} {
    error "No hardware targets detected"
}

open_hw_target [lindex $targets 0]
puts "SMOKE_STEP_PASS open_hw_target"

set devices [get_hw_devices]
puts "SMOKE_HW_DEVICE_COUNT [llength $devices]"
if {[llength $devices] == 0} {
    error "No hardware devices detected"
}

set program_device ""
foreach dev $devices {
    set part [get_property PART $dev]
    puts "SMOKE_HW_DEVICE [get_property NAME $dev] PART=$part"
    if {$part eq $expected_part} {
        set program_device $dev
        break
    }
}
if {$program_device eq ""} {
    error "No $expected_part hardware device found; refusing to program"
}

current_hw_device $program_device
refresh_hw_device -update_hw_probes false $program_device
set_property PROGRAM.FILE $bit_file $program_device
program_hw_devices $program_device
refresh_hw_device -update_hw_probes false $program_device
puts "SMOKE_STEP_PASS program_hw_devices"

close_hw_target
disconnect_hw_server
puts "SMOKE_ALL_PASS_HW_PROGRAM"
exit
