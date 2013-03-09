package DreamCatcher::Role::DBH;
# ABSTRACT: Provides the database connection for the feathers

use Moo::Role;
use Sub::Quote;
use DBIx::Connector;
use Exception::Class::DBI;

requires qw(config log);

has 'dbh' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_dbh',
);

has 'sql' => (
    is      => 'rwp',
    isa     => quote_sub(q{die "Not a HashRef" unless ref $_[0] eq 'HASH'; }),
    builder => '_build_sql',
);

sub _build_sql { {} }

sub sth {
    my ($self,$name) = @_;

    if( !exists $self->sql->{$name} ) {
        $self->log(error => "attempt to load unknown statement:$name");
        return;
    }

    return $self->dbh->run( fixup => sub {
        my $sth;
        eval {
            $self->log(debug => "preparing $name");
            $sth = $_->prepare( $self->sql->{$name} );
        };
        if( my $err = $@ ) {
            $self->log( error => join(" - ", ref $err, $err->errstr ));
        }
        return $sth;
    });
}

sub _build_dbh {
	my ($self) = @_;

	die "No db section in config!" unless exists $self->config->{db} && ref $self->config->{db} eq 'HASH';

	my %db = %{ $self->config->{db} };
	my $dbconn = DBIx::Connector->new( @db{qw(dsn user pass)}, {
            RaiseError  => 1,
            HandleError => Exception::Class::DBI->handler,
    });
    if( !defined $dbconn ) {
        $self->log( fatal => "Database setup failed" );
        die "DB setup failed";
    }
    $self->log( debug => "Database established" );
    return $dbconn;
}

# Return TRUE
1;
