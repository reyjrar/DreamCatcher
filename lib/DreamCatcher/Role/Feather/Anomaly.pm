package DreamCatcher::Role::Feather::Anomaly;
# ABSTRACT: Role container to handle anomaly scores

use Moo::Role;
use Sub::Quote;

has 'scores' => (
    is => 'ro',
    isa => quote_sub(q{die "Not a hash reference" unless ref $_[0] eq 'HASH'}),
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

# Return True
1;
