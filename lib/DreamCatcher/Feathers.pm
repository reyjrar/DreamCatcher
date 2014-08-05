package DreamCatcher::Feathers;

use Moo;
use Sub::Quote;
use Tree::DAG_Node;
use Module::Pluggable (
    instantiate => 'new',
    search_path => 'DreamCatcher::Feather',
);

# Attributes
has 'tree' => (
    is      => 'ro',
    isa      => quote_sub(q{ die "Not an Object" unless ref $_[0]; }),
    lazy    => 1,
    builder => '_build_tree',
);
has 'hash' => (
    is      => 'ro',
    isa      => quote_sub(q{ die "Not a HashRef" if ref $_[0] ne 'HASH'; }),
    lazy    => 1,
    builder => '_build_hash'
);
has 'config' => (
    is       => 'ro',
    isa      => quote_sub(q{ die "Not a HashRef" if ref $_[0] ne 'HASH'; }),
    init_arg => 'Config',
);
has 'log_callback' => (
    is       => 'ro',
    isa      => quote_sub(q{die "Not a CodeRef" if ref $_[0] ne 'CODE'; }),
    default  => sub { my $l = sub { warn join(": ", @_), "\n" }; return $l; },
    init_arg => 'Log',
);

# Collect all of the plugins, though not ordered
sub _build_hash {
    my $self = shift;
    return { map { $_->name => $_ } grep { $_->enabled } $self->plugins( Config => $self->config, Log => $self->log_callback ) };
}

# DAG Tree for determining plguin ordering
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
                # Possible throw exception?
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

# Order the plugins using their "parent" attributes
sub chain {
    my ($self,$function) = @_;
    my $F = $self->hash;
    return [ map { $F->{$_} } map { $_->name } grep { defined $function ? $F->{$_->name}->function eq $function : 1; } $self->tree->descendants ];
}

# Run the processing
sub process {
    my ($self,$packet) = @_;

    foreach my $feather (@{ $self->chain('sniffer') }) {
        $feather->process($packet);
    }
    return 1;
}

sub schedule {
    my $self = @_;
}

# Return True
1;
