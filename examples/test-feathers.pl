#!/usr/bin/env perl
#
use strict;
use warnings;
use YAML qw(Dump LoadFile);

use lib "$ENV{HOME}/code/dreamcatcher/lib";
use DreamCatcher::Feathers;

my $feathers = DreamCatcher::Feathers->new(Config => LoadFile("$ENV{HOME}/code/dreamcatcher/dreamcatcher.yml"));
print Dump($feathers->feathers);
my $collection = $feathers->chain();

foreach my $feather ( @{ $collection }) {
    printf "loaded %s [%d] after %s\n", $feather->name, $feather->priority, $feather->after;
}
