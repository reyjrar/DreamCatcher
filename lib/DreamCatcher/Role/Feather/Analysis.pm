package DreamCatcher::Role::Feather::Analysis;

use Moose::Role;
use namespace::autoclean;
with qw(
    DreamCatcher::Role::Feather
    DreamCatcher::Role::DBH
    DreamCatcher::Role::Logger
);
use DreamCatcher::Types qw(PositiveInt);

requires qw(analyze);

has 'default_interval' => (
    is      => 'ro',
    isa     => PositiveInt,
    builder => '_build_interval',
);

# Set the function
sub _build_function { 'analysis'; }

# Default is process every 10 minutes
sub _build_interval { 600; }

sub interval {
    my $self = shift;
    return exists $self->config->{interval} && $self->config->{interval} > 0 ? $self->config->{interval} : $self->default_interval;
}


my %_sld_needs_more = map { $_ => 1 } qw(co com net org);
sub strip_sld {
    my $self = shift;
    my ($domain) = @_;

    my $without_sld = undef;
    chomp($domain);
    my @parts = map { lc } split /\./, $domain;

    return unless @parts > 2;

    return if $parts[-1] eq 'arpa' && $parts[-2] eq 'in-addr';
    pop @parts;
    pop @parts;
    pop @parts if exists $_sld_needs_more{$parts[-1]};

    return join('.', @parts);
}

no Moose::Role;
# Return True
1;
