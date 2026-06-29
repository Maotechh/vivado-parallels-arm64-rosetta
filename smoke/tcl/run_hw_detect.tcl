puts "SMOKE_VERSION [version -short]"
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
foreach dev $devices {
    puts "SMOKE_HW_DEVICE [get_property NAME $dev] PART=[get_property PART $dev]"
}
if {[llength $devices] == 0} {
    error "No hardware devices detected"
}

close_hw_target
disconnect_hw_server
puts "SMOKE_ALL_PASS_HW_DETECT"
exit
