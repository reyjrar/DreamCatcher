package DreamCatcher::Role::DBH;
# ABSTRACT: Provides the database connection for the feathers

use Moo::Role;
use Sub::Quote;
use DBIx::Connector;

requires qw(config);

has 'dbh' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_dbh',
);

has 'sql' => (
    is      => 'rwp',
    isa     => quote_sub(q{die "Not a HashRef" unless ref $_[0] eq 'HASH'; }),
    builder => '_build_sql',
    default => sub { {} },
);

has 'cached_sth' => (
    is      => 'rw',
    isa     => quote_sub(q{die "Not a HashRef" unless ref $_[0] eq 'HASH'; }),
    default => sub { {} },
);

sub sth {
    my ($self,$name) = @_;

    return $self->cached_sth if exists $self->cached_sth->{$name};
    return undef unless $self->sql->{$name};

    return $self->cached_sth->{$name} = $self->dbh->run( fixup => sub {
            my $sth = $_->prepare( $self->sql->{$name} );
            $sth;
        }, catch {
            my $err = shift;
        }
    );
}

sub _build_dbh {
	my ($self) = @_;

	die "No db section in config!" unless exists $self->config->{db} && ref $self->config->{db} eq 'HASH';

	my %db = %{ $self->config->{db} };
	return DBIx::Connector->new( @db{qw(dsn user pass)}, { RaiseError => 0 });
}

# Return TRUE
1;
