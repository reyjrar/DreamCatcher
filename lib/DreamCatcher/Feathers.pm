package DreamCatcher::Feathers;

use Moose;

use Tree::DAG_Node;
use Module::Pluggable (
    instantiate => 'new',
    search_path => 'DreamCatcher::Feather',
);

# Attributes
has 'tree' => (
    is      => 'ro',
    isa      => 'Tree::DAG_Node',
    lazy    => 1,
    builder => '_build_tree',
);
# DAG Tree for determining plugin ordering
sub _build_tree {
    my $self = shift;
    my $tree = Tree::DAG_Node->new();
    $tree->name("DreamCatcher::Feathers");

    # Build the feathers list
    my $F = $self->hash;
    my @feathers = map { { tries => 0, obj => $F->{$_} } } sort { $F->{$a}->priority <=> $F->{$b}->priority } keys %{ $F };

    # Object cache
    my %objects = ();

    # Cycle through the feathers
    while ( my $feather = shift @feathers ) {
        my $node;
        my $obj = $feather->{obj};

        # Skip feathers that are disabled
        next unless $obj->enabled;

        if( $obj->parent eq 'none' ) {
            $node = $tree->new_daughter();
        }
        elsif( exists $objects{$obj->parent} ) {
            $node = $objects{$obj->parent}->new_daughter();
        }
        else {
            # Retry, may be out of order
            $feather->{tries}++;
            if($feather->{tries} > 3) {
                warn sprintf "DreamCatcher::Feathers::_build_tree failed to load %s, tries exceeded.", $obj->name;
            }
            else {
                push @feathers, $feather;
            }
            next;
        }
        $node->name($obj->name);
        $objects{$obj->name} = $node;
    }
    return $tree;
}

has 'config' => (
    is       => 'ro',
    isa      => 'HashRef',
    init_arg => 'Config',
);

has 'log_callback' => (
    is       => 'ro',
    isa      => 'CodeRef',
    default  => sub { my $l = sub { warn join(": ", @_), "\n" }; return $l; },
    init_arg => 'Log',
);

has 'hash' => (
    is      => 'ro',
    isa      => 'HashRef',
    lazy    => 1,
    builder => '_build_hash'
);
sub _build_hash {
    my $self = shift;
    return { map { $_->name => $_ } grep { $_->enabled } $self->plugins( Config => $self->config, Log => $self->log_callback ) };
}

has 'schedule' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_schedule'
);
sub _build_schedule {
    my ($self) = @_;
    my %sched = map { $_->name => $_->interval } @{ $self->chain('analysis') };
    return \%sched;
}

# Order the plugins using their "parent" attributes
sub chain {
    my ($self,$function) = @_;
    my $F = $self->hash;
    return [ map { $F->{$_} } map { $_->name } grep { defined $function ? $F->{$_->name}->function eq $function : 1; } $self->tree->descendants ];
}

# Run the processing
sub process {
    my ($self,$packet) = @_;

    # Skip junk data
    if( !defined $packet || !$packet->valid ) {
        return;
    }
    foreach my $feather (@{ $self->chain('sniffer') }) {
        $feather->process($packet);
    }
    return 1;
}


__PACKAGE__->meta->make_immutable;
1;
