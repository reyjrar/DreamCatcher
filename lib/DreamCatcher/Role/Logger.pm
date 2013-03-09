package DreamCatcher::Role::Logger;
# ABSTRACT: Provides logging for the feathers

use Moo::Role;
use Sub::Quote;
use Log::Log4perl;
use Log::Dispatch::FileRotate;

has 'logger' => (
    is       => 'ro',
    isa      => quote_sub(q{die "Not a CodeRef" if ref $_[0] ne 'CODE'; }),
    required => 1,
    init_arg => 'Log',
);

sub log {
    my $self = shift;

    $self->logger->( @_ );
}


# Return TRUE
1;
