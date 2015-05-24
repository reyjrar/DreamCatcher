package DreamCatcher::Role::Cache;
# ABSTRACT: Provides a caching API for the feathers

use Moose::Role;
use namespace::autoclean;
use CHI;
use Cache::FastMmap;

has 'cache' => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_cache',
    init_arg => undef,
);

sub _build_cache {
	my ($self) = @_;

	return CHI->new(driver => 'FastMmap', namespace => $self->name, expires_in => 30);
}

no Moose::Role;
# Return TRUE
1;
