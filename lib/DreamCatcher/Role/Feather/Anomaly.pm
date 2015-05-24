package DreamCatcher::Role::Feather::Anomaly;
# ABSTRACT: Role container to handle anomaly scores

use Moose::Role;
use namespace::autoclean;
with 'DreamCatcher::Role::Feather';

has 'scores' => (
    is => 'ro',
    isa => 'HashRef',
    builder => '_build_scores',
);

sub _build_scores {
    return {
        abnormal     => 10,
        obsolete     => 10,
        mismatch     => 15,
        unassigned   => 15,
        private      => 20,
        experimental => 30,
        suspicious   => 50,
        malicious    => 100,
    };
}

sub score {
    my $self = shift;
    my $type = shift;
    return exists $self->scores->{$type} ? $self->scores->{$type} : 5;
}

no Moose::Role;
# Return True
1;
