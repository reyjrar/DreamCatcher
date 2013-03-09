package DreamCatcher::Role::Feather;

use Moo::Role;
use Sub::Quote;

requires qw(process);

has 'name'  => (
    is      => 'ro',
    isa     => quote_sub(q{ die "Not a string" if ref $_[0] || $_[0] =~ /[^0-9a-z:_\-]/i; }),
    builder => '_build_name',
);
has 'parent' => (
    is      => 'ro',
    isa     => quote_sub(q{ die "Not a string" if ref $_[0] || $_[0] =~ /[^0-9a-z:_\-]/i; }),
    builder => '_build_parent',
);
has 'priority' => (
    is      => 'ro',
    isa     => quote_sub(q{ die "Not an integer" if ref $_[0] || $_[0] =~ /[^0-9]/i; }),
    builder => '_build_priority',
);
has 'enabled' => (
    is      => 'ro',
    isa     => quote_sub(q{ die "Not a bool" if ref $_[0]; }),
    lazy    => 1,
    builder => '_build_enabled',
);
has 'config' => (
    is       => 'ro',
    isa      => quote_sub(q{ die "Not a HashRef" if ref $_[0] ne 'HASH'; }),
    init_arg => 'Config',
);
# Default, can be overridden in children
sub _build_priority { 10; }

# Default, can be overridden in children
sub _build_parent { 'none'; }

# Default, enabled
sub _build_enabled {
    my $self = shift;
    my $config = $self->config;

    if( defined $config && ref $config eq 'HASH' && exists $config->{disabled} ) {
        return !$config->{disabled};
    }
    return 1;
}

# Default Naming Convention
sub _build_name {
    my $self = shift;
    my $class = ref $self;

    if( my($name) = ( $class =~ /\:\:Feather\:\:(.*)/ ) ) {
        return $name;
    }
    die "cannot guess $class name and none is set, override _build_name().\n";
}

# Wrap the BUILDARGS function
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my %args = @_;

    my $prefix = "DreamCatcher::Feather::";
    my $name = substr($class, length $prefix);

    my %FeatherConfig = ();
    if( exists $args{Config} ) {
        if( exists $args{Config}->{$name} ) {
            %FeatherConfig = %{ $args{Config}->{$name} };
        }
        if( exists $args{Config}->{db} ) {
            $FeatherConfig{db} = \%{ $args{Config}->{db} };
        }
    }
    $class->$orig( Config => \%FeatherConfig, Log => $args{Log} );
};

# Wrap the process function
around process => sub {
    my $orig = shift;
    my $class = shift;
    my $packet = shift;

    if( defined $packet && $packet->valid ) {
        $class->$orig( $packet );
    }
};


# Return True
1;
