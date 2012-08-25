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
    is => 'ro',
    isa => 'Bool',
    lazy => 1,
    builder => '_build_enabled',
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

# Return True
1;
