package DreamCatcher::Feather::list::meta;
# ABSTRACT: Link questions and answers to the list collection

use Moo;
with qw(
    DreamCatcher::Role::Feather::Analysis
    DreamCatcher::Role::Logger
);
use POSIX qw(strftime);

sub _build_sql {
    return {
        check => q{
            select z.id as zone_id, l.id as list_entry_id, l.list_id as list_id
                from list_entry l
                    inner join zone z on z.path <@ l.path
        },
        check_answer    => q{select answer_id from zone_answer where zone_id = ?},
        check_question  => q{select question_id from zone_question where zone_id = ?},
        insert_answer   => q{insert into list_meta_answer ( answer_id, list_entry_id, list_id ) values ( ?, ?, ? )},
        insert_question => q{insert into list_meta_question ( question_id, list_entry_id, list_id ) values ( ?, ?, ? )},
    };
}

sub analyze {
    my ($self) = @_;

    my %STH = map { $_ => $self->sth($_) } keys %{ $self->sql };

    $STH{check}->execute();
    my $updates = 0;
    while( my $ent = $STH{check}->fetchrow_hashref ) {
        foreach my $type (qw(question answer)) {
            $STH{"check_$type"}->execute( $ent->{zone_id} );
            while ( my ($id) = $STH{"check_$type"}->fetchrow_array ) {
                eval {
                    $STH{"insert_$type"}->execute( $id, $ent->{list_entry_id}, $ent->{list_id} );
                };
                $updates++ unless $@;
            }
        }
    }
    $self->log( debug => "list::meta posted $updates updates");
}

1;
