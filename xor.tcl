set ns [new Simulator]

set tf [open xor.tr w]
$ns trace-all $tf

set nf [open xor.nam w]
$ns namtrace-all $nf

proc finish {} {
    global ns nf tf
    $ns flush-trace
    close $tf 
    close $nf
    exit 0
}

set ra {}
Agent/UDP instproc process_data {size data} {
    global ns
    global ra
    $self instvar node_
    global udp3
    $ns trace-annotate "Bit recieved at Node [$node_ node-addr]: {$data}"
    lappend ra $data
    if {[llength $ra] == 2} {
        set res [expr [lindex $ra 0] ^ [lindex $ra 1]]
        $ns trace-annotate "XOR : {$res}"
        unset ra
        set ra {}
        eval {$udp3} send 500 {$res}
        $ns trace-annotate "Bit sent to Sink : {$res}"
    }
}

proc send_pkt {nod agent msg} {
    global ns
    $ns trace-annotate "Bit sent by Node [$nod node-addr]: {$msg}"
    eval {$agent} send 500 {$msg}
}

set node1 [$ns node]
$node1 color blue
$node1 label "X"

set node2 [$ns node]
$node2 color red
$node2 label "Y"

set node3 [$ns node]
$node3 color green
$node3 label "X'.Y + X.Y'"

set node4 [$ns node]
$node4 color black
$node4 label "Sink"

$ns simplex-link $node1 $node3 5Mb 1ms DropTail
$ns simplex-link $node2 $node3 5Mb 1ms DropTail
$ns simplex-link $node3 $node4 5Mb 1ms DropTail

set udp1 [new Agent/UDP]
$ns attach-agent $node1 $udp1
$udp1 set fid_ 0

set udp2 [new Agent/UDP]
$ns attach-agent $node2 $udp2
$udp2 set fid_ 1

set udp3 [new Agent/UDP]
$ns attach-agent $node3 $udp3

set null [new Agent/Null]
$ns attach-agent $node4 $null

$ns connect $udp1 $udp3
$ns connect $udp2 $udp3
$ns connect $udp3 $null

set k 0
puts "Starting Simulation..."
$ns at 0.00 "$ns trace-annotate {Simulation Started}"
for {set i 0} {$i < 2} {incr i} {
    for {set j 0} {$j < 2} {incr j} {
        $ns at [expr 0.40+$k] "send_pkt $node1 $udp1 $i"
        $ns at [expr 0.40+$k] "send_pkt $node2 $udp2 $j"
    set k [expr $k+0.2]
    }
}
puts "Stopping Simulation..."
$ns at 1.30 "$ns trace-annotate {Simulation Stopped}"
$ns at 1.31 "$ns detach-agent $node1 $udp1; $ns detach-agent $node2 $udp2; $ns detach-agent $node3 $null"
$ns at 1.32 "finish"
$ns run