package DreamCatcher::Role::Feather;

use Mouse::Role;

has 'name'  => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_name',
);
has 'after' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_after',
);
has 'priority' => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build_priority',
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
sub _build_after { 'base'; }

# Default, enabled
sub _build_enabled { 1; }

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
    if( exists $args{Config} && exists $args{Config}->{$name} ) {
        %FeatherConfig = %{ $args{Config}->{$name} };
    }

    $class->$orig( Config => \%FeatherConfig );
};

# Return True
1;
