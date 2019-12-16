#!/usr/bin/perl -w

use strict;

print '#!/bin/bash' . "\n";

while(defined(my $line = <STDIN>)) {
    chomp($line);
    my @fields = split(/\t/, $line);
    my $onid = $fields[0];
    my $encpass = $fields[1];
    my $fullname = $fields[2];
#    my $create_str = "sudo adduser -c \"" . $fullname . 
    #	"\" --expiredate 2017-12-10 -p \'" . $encpass . "\' " . $onid;
    my $create_str = "useradd -p \'" . $encpass . "\'" . $onid;
    print $create_str . "\n";
}
