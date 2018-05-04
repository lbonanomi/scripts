#!/usr/bin/expect -f

# Funny thing: Riverbed network devices implement a limited BASH and a limited SSH, making it impossible to run
# ssh $host "$commands". This script is an effort to smooth-over such issues

set host [lindex $argv 0];              # Get host value, including a username. 'hostname' and 'user@hostname' are both legal.

set password [lindex $argv 1];          # Get password from commandline

set cmdArg "";                          # Everything else may be considered a remote command to run. Everything
set cmdCnt 0;                           # after the first 2 args will be considered a command. BEWARE!! Multiple
foreach arg $argv {                     # commands *MAY* be specified on a single line **BUT** they are separated
    if {$cmdCnt > 1} {                  # by _ESCAPED_ colons '\:' **NOT** semi-colons ':'
        lappend cmdArg $arg;
    }
    incr cmdCnt;
}

set cleaned [ join $cmdArg " " ];       # Remove TCL braces.
set cmdList [split "$cleaned" "\:" ];   # split command string into newlines on ':'

set timeout 30;

spawn -noecho $env(SHELL);
match_max 100000;

sleep 1;

send -- "ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $host\r";
expect -exact "ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $host";

# Expect *some* variation on a password prompt. Time out quickly (30s) in case of bad passwords or dead links
expect {
    "sword" { send -- "$password\r"; }
    timeout { exit; }
}

expect {
    "Last" { sleep 5; send -- "\r"; } # 'Last login' is pretty universal, right?
    timeout { exit; }
}

foreach cmdArg $cmdList {
    set cleaned [ join $cmdArg " " ];

    puts -nonewline "";
    send "$cleaned\r";
    sleep 1;

    set trigger [ string trimleft $cleaned \| ]

    puts -nonewline "EXPECTING: ";
    puts -nonewline "$trigger";
    puts -nonewline " NOT: ";
    puts -nonewline $cleaned;
    expect "$cleaned";
    puts -nonewline "";
}
