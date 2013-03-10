package DreamCatcher::Role::Feather::Sniffer;

use Moo::Role;
use Sub::Quote;

with 'DreamCatcher::Role::Feather';

requires qw(process);

sub _build_function { 'sniffer'; }

# Wrap the process function
around process => sub {
    my $orig = shift;
    my $class = shift;
    my $packet = shift;

    if( defined $packet && $packet->valid ) {
        $class->$orig( $packet );
    }
};


# Return True
1;
