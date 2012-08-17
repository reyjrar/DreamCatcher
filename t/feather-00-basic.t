use strict;

use Test::More tests => 2;

BEGIN {
    use_ok( 'DreamCatcher::Feathers' );
};

my $feathers;
eval {
    $feathers = DreamCatcher::Feathers->new();
};
ok( defined $feathers );
