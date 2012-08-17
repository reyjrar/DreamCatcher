package DreamCatcher::Feathers;

use Mouse;
use Tree::DAG_Node;
use Module::Pluggable => (
    instantiate => 1,
    search_path => 'DreamCatcher::Feathers',
);

has 'tree' => (
    is => 'ro',
    isa => 'Object',
    lazy => 1,
    builder => '_build_tree',
);

has 'chain' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_chain',
);

has 'feathers' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_feathers'
);


# Collect all of the plugins, though not ordered
sub _build_feathers {
    my $self = shift;
    return [ sort { $a->priority <=> $b->priority } @{ $self->plugins } ];
}

# DAG Tree for determining plguin ordering
sub _build_tree {
    my $tree = Tree::DAG_Node->new();
    $tree->name("DreamCatcher::Feathers");

    # Build the feathers list
    my @feathers = map { { tries => 0, obj => $_ } } @{ $self->feathers };

    my %objects = ();

    # Cycle through the feathers
    while ( my $feather = shift @feathers ) {
        my $node;
        my $obj = $feather->{obj};
        if( $obj->after eq 'none' ) {
            $node = $tree->new_daughter();
        }
        elsif( exists $objects{$obj->after} ) {
            $node = $objects{$obj->after}->new_daughter();
        }
        else {
            # Retry, maybe out of order
            $feather->{tries}++;
            if($feather->{tries} > 3) {
                # Possible throw exception?
                next;
            }
            push @feathers, $obj;
        }
        $node->name($obj->name);
        $objects{$obj->name} = $node;
    }
    return $tree;
}

# Order the plugins using their "after" attributes
sub _build_chain {
    my $self = shift;
}

# Return True
1;
