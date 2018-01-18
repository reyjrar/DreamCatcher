package DreamCatcher::Role::Logger;
# ABSTRACT: Provides logging for the feathers

use Moose::Role;
use namespace::autoclean;
use Log::Log4perl;
use Log::Dispatch::FileRotate;

has 'logger' => (
    is       => 'ro',
    isa      => 'CodeRef',
    required => 1,
    init_arg => 'Log',
);

sub log {
    my $self = shift;

    $self->logger->( @_ );
}

no Moose::Role;
# Return TRUE
1;
