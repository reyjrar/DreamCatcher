package DreamCatcher::Role::Feather::Sniffer;

use Mouse::Role;

requires qw(process);

around 'process' => sub {
    my $self = shift;
    my $orig = shift;
    my ($packet,$data) = @_;

    # Check to ensure that the previous feather was successful
    if( $self->after ne 'none' ) {
        if( !exists $data->{_status}{$self->after} || $data->{_status}{$self->after} ) {
            return $packet;
        }
    }

    # We're OK, call the method
    return $self->$orig($packet,$data);
};

# Return True
1;
