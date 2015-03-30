package DreamCatcher::Feather::conversation;
# ABSTRACT: Determine which conversation this packet belongs to.

use strict;
use warnings;
use Moo;

with qw(
    DreamCatcher::Role::Feather::Sniffer
    DreamCatcher::Role::Logger
	DreamCatcher::Role::DBH
);

# Override default priority
sub _build_priority { 1; }

sub process {
    my ($self,$packet) = @_;

    # Conversations
	my $dbError = undef;
	my $sth = $self->dbh->run( fixup => sub {
        my $lsh;
        eval {
			$lsh = $_->prepare('select * from find_or_create_conversation( ?, ? )');
            $lsh->execute( $packet->details->{client}, $packet->details->{server} );
        };
        if( my $err = $@ ) {
		    $dbError = "find_or_create_conversation failed: " . join(' - ', ref $err, $err->errstr);
        }
        return $lsh;
    });

	if( !defined $dbError && defined $sth && $sth->rows > 0 ) {
		# Set conversation id
		my $convo = $sth->fetchrow_hashref;
        $self->log(debug => "conversation bits: " . join( ",", map { "$_ => $convo->{$_}" } keys %{ $convo }) );
		$packet->details->{client_id} = $convo->{client_id};
		$packet->details->{server_id} = $convo->{server_id};
		$packet->details->{conversation_id} = $convo->{id};
	}
    else {
        $self->log(error => "failed conversation lookup: '$dbError'");
    }
}

__PACKAGE__->meta->make_immutable;
