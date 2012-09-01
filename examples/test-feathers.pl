#!/usr/bin/env perl
#
use strict;
use warnings;

use lib '/Users/brad/code/dreamcatcher/lib';
use DreamCatcher::Feathers;

my $feathers = DreamCatcher::Feathers->new();
my $collection = $feathers->chain();

foreach my $feather ( @{ $collection }) {
    printf "loaded %s [%d] after %s\n", $feather->name, $feather->priority, $feather->after;
}
