package DreamCatcher::Controller::Main;
# ABSTRACT: DreamCatcher Front Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;

	my $sth = $self->dbconn->run( fixup => sub {
		my $dbh = shift;
		return $dbh->prepare(qq{
			select server.ip, count(1) as clients
				from conversation
			  		inner join server on conversation.server_id = server.id
				where conversation.last_ts > NOW() - interval '15 days'
					group by server.ip
		});
	});
	$sth->execute;

    $self->render();
}

1;
