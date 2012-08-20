use strict;

use Test::More;

BEGIN {
    use_ok( 'DreamCatcher::Feathers' );
};

my $plumage = new_ok( "DreamCatcher::Feathers" );

# By calling chain, we test feathers and tree as well
foreach my $feather ( @{ $plumage->chain } ) {
    can_ok( $feather, qw{name priority after process});
}

# Now we're OK
done_testing();
