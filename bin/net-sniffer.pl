#!/usr/bin/env perl
# PODNAME: net-sniffer.pl

use strict;
use warnings;

use FindBin;


use lib "${FindBin::Bin}/../lib";
use DreamCatcher::Feathers;
use DreamCatcher::Net::Pcap;

my $Config = {};

# Instantiate the Feathers
my $Feathers = DreamCatcher::Feathers->new( Config => $Config->{feathers} );

# Instantiate the Net
my $Net = DreamCatcher::Net::Pcap->new( Config => $Config );
