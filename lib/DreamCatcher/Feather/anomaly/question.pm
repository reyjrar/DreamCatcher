package DreamCatcher::Feather::anomaly::question;
# ABSTRACT: Calculate anomaly score for a question based on weirdness

use Const::Fast;
use JSON::XS;
use Moose;
with qw(
    DreamCatcher::Role::Feather::Analysis
    DreamCatcher::Role::Feather::Anomaly
);
use POSIX qw(strftime);
use Text::Soundex;
use Text::Unidecode;

const my %RR_TYPES => (
    # Common
    A              => 'common',
    AAAA           => 'common',
    CAA            => 'common',
    CNAME          => 'common',
    DLV            => 'common',
    DNSKEY         => 'common',
    DNAME          => 'common',
    DS             => 'common',
    KEY            => 'common',
    MX             => 'common',
    NS             => 'common',
    PTR            => 'common',
    RRSIG          => 'common',
    SOA            => 'common',
    SIG            => 'common',
    SPF            => 'common',
    SRV            => 'common',
    SSHFP          => 'common',
    TA             => 'common',
    TKEY           => 'common',
    TSIG           => 'common',
    # Obsolete
    A6             => 'obsolete',
    MAILA          => 'obsolete',
    MAILB          => 'obsolete',
    MD             => 'obsolete',
    MF             => 'obsolete',
    MINFO          => 'obsolete',
    # Suspicious
    ANY            => 'suspicious',
    AXFR           => 'suspicious',
    IXFR           => 'suspicious',
    HINFO          => 'suspicious',
    # Experimental
    MB             => 'experimental',
    MG             => 'experimental',
    MR             => 'experimental',
    NULL           => 'experimental',
);

const my %CLASSES => (
    # Obsolete
    CH => 'obsolete',
    HS => 'obsolete',
);

sub _build_sql {
    return {
        check => q{
            select
                q.id,
                q.class,
                q.type,
                q.name
            from question q
                left join anomaly_question aq on q.id = aq.id
            where
                aq.id is null
        },
        insert => q{
            insert into anomaly_question ( source, id, score, checks, results ) values ( 'question', ?, ?, ?, ? )
        },
    };
}

sub analyze {
    my $self = shift;

    my %STH = map { $_ => $self->sth($_) } keys %{ $self->sql };

	my $updates = 0;
    my $errors  = 0;

	$STH{check}->execute();
	while( my $ent = $STH{check}->fetchrow_hashref ) {
        my $score = 0;
        my %analysis = ();

        # Check classes
        if(exists $CLASSES{$ent->{class}} || $ent->{class} =~ /^(?:CLASS)?([0-9]+)/ ) {
            my $id = $1;
            my $type = exists $CLASSES{$ent->{class}} ? $CLASSES{$ent->{class}}
                     : defined($id) && $id >= 65280 && $id < 65535  ? 'private'
                     : 'unassigned';
            $score += $self->score($type);
            my $key = sprintf "question_%s_class", $type;
            $analysis{$key} = defined $id ? $id : $ent->{class};
        }

        # Check Types
        if((exists $RR_TYPES{$ent->{type}} && $RR_TYPES{$ent->{type}} ne 'common') || $ent->{type} =~ /^(?:TYPE)?([0-9]+)/ ) {
            my $id = $1;
            my $type = exists $RR_TYPES{$ent->{type}} ? $RR_TYPES{$ent->{type}}
                     : defined($id) && $id >= 65280 && $id < 65535  ? 'private'
                     : defined($id) ? 'unassigned'
                     : 'abnormal';
            $score += $self->score($type);
            my $key = sprintf "question_%s_type", $type;
            $analysis{$key} = defined $id ? $id : $ent->{type};
        }

        # Check for weird hostnames by length
        my $hostname = lc ($ent->{name});
        my $name_length = defined $ent->{name} ? length $ent->{name} : 0;
        if( $name_length <= 1 || $name_length > 52 ) {
            my $type = $name_length <= 1  ? 'abnormal'
                     : $name_length > 78  ? 'malicious'
                     : 'suspicious';
            my $key  = sprintf "question_%s_length", $type;
            $score += $self->score($type);
            $analysis{$key} = $name_length;
        }

        # Check for lack of soundex outside of second-level domain
        if( my $short = $self->strip_sld($hostname) ) {
            my $valid_soundex=0;
            my $pieces=0;
            foreach my $piece ( grep { defined && length } split /[^a-z]+/, unidecode($short) ) {
                next unless length $piece >= 2;
                $pieces++;
                $valid_soundex++ if defined soundex($piece);
            }

            if( !$valid_soundex ) {
                my $type = $pieces > 10 ? 'malicious'
                         : $pieces >  5 ? 'suspiciois'
                         : 'abnormal';
                $score += $self->score($type);
                $analysis{sprintf "question_%s_soundex", $type} = sprintf "short=%s,pieces=%s", $short, $pieces;
            }
        }

        # Mark this as done
        eval { $STH{insert}->execute($ent->{id},$score,[qw(classes types length soundex)],encode_json(\%analysis)) };
        if(my $ex = $@) {
            $self->log(error => "anomaly::question - failed to score $ent->{id}: $ex");
            $errors++;
        }
        else {
            $updates++;
        }
    }

	$self->log(info => "anomaly::question posted $updates updates, $errors errors");
}


__PACKAGE__->meta->make_immutable;
1;
