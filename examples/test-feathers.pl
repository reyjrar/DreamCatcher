#!/usr/bin/env perl
#
use strict;
use warnings;
use YAML qw(Dump LoadFile);

use lib "$ENV{HOME}/code/dreamcatcher/lib";
use DreamCatcher::Feathers;

my $feathers = DreamCatcher::Feathers->new(Config => LoadFile("$ENV{HOME}/code/dreamcatcher/dreamcatcher.yml"));
printf("Feathers found %s(%s):  => %s\n", $_->name, $_->priority, $_->parent ) for values %{ $feathers->hash };

my $collection = $feathers->chain('analysis');

foreach my $feather ( @{ $collection }) {
    printf "chained %s [%d] after %s\n", $feather->name, $feather->priority, $feather->parent;
}
