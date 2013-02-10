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
has 'chain' => (
    is      => 'ro',
    isa      => quote_sub(q{ die "Not a HashRef" if ref $_[0] ne 'ARRAY'; }),
    lazy    => 1,
    builder => '_build_chain',
);
has 'feathers' => (
    is      => 'ro',
    isa      => quote_sub(q{ die "Not a HashRef" if ref $_[0] ne 'HASH'; }),
    lazy    => 1,
    builder => '_build_feathers'
);
has 'config' => (
    is       => 'ro',
    isa      => quote_sub(q{ die "Not a HashRef" if ref $_[0] ne 'HASH'; }),
    init_arg => 'Config',
);

# Collect all of the plugins, though not ordered
sub _build_feathers {
    my $self = shift;
    return { map { $_->name => $_ } grep { $_->enabled } $self->plugins( Config => $self->config ) };
}

# DAG Tree for determining plguin ordering
sub _build_tree {
    my $self = shift;
    my $tree = Tree::DAG_Node->new();
    $tree->name("DreamCatcher::Feathers");

    # Build the feathers list
    my $F = $self->feathers;
    my @feathers = map { { tries => 0, obj => $F->{$_} } } sort { $F->{$a}->priority <=> $F->{$b}->priority } keys %{ $F };

    # Object cache
    my %objects = ();

    # Cycle through the feathers
    while ( my $feather = shift @feathers ) {
        my $node;
        my $obj = $feather->{obj};

        # Skip feathers that are disabled
        next unless $obj->enabled;

        if( $obj->after eq 'none' ) {
            $node = $tree->new_daughter();
        }
        elsif( exists $objects{$obj->after} ) {
            $node = $objects{$obj->after}->new_daughter();
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

# Order the plugins using their "after" attributes
sub _build_chain {
    my $self = shift;
    my $F = $self->feathers;
    return [ map { $F->{$_} } map { $_->name } $self->tree->descendants ];
}

# Return True
1;
