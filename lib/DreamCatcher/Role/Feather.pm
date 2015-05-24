package DreamCatcher::Role::Feather;

use Moose::Role;
use namespace::autoclean;

has 'name'  => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_name',
);
has 'function'  => (
    is       => 'ro',
    isa      => 'Str',
    builder  => '_build_function',
    init_arg => undef,
);
has 'parent' => (
    is       => 'ro',
    isa      => 'Str',
    builder  => '_build_parent',
    init_arg => undef,
);
has 'priority' => (
    is       => 'ro',
    isa      => 'Str',
    builder  => '_build_priority',
    init_arg => undef,
);
has 'enabled' => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    builder => '_build_enabled',
);
has 'config' => (
    is       => 'ro',
    isa      => 'HashRef',
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

no Moose::Role;
# Return True
1;
