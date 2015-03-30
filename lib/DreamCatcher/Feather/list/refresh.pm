package DreamCatcher::Feather::list::refresh;
# ABSTRACT: Perform list based refreshes

use LWP::Simple;
use Moo;
with qw(
    DreamCatcher::Role::Feather::Analysis
    DreamCatcher::Role::Logger
);
use POSIX qw(strftime);

use strict;
use warnings;

# Run check once an hour
sub _build_interval { 3600; }

sub _build_sql {
    return {
        check             => q{
            select
                id,
                refresh_url,
                refresh_last_ts
            from list
                where can_refresh = true
                    and (refresh_last_ts IS NULL OR NOW() - refresh_last_ts > refresh_every)
        },
        refresh_entry     => q{select refresh_list_entry(?, ?, ?)},
        unset_refresh     => q{update list_entry set refreshed = false where list_id = ?},
    };
}

sub analyze {
    my ($self) = @_;

    my %STH = map { $_ => $self->sth($_) } keys %{ $self->sql };

    $STH{check}->execute();

    my $total = 0;
    while(my $list = $STH{check}->fetchrow_hashref) {
        # Attempt to pull the refresh
        my $content = get($list->{refresh_url});
        if(!defined $content) {
            $self->log(warn => sprintf "Refreshing failed %s, no content.", $list->{refresh_url});
            next;
        }
        $self->log(info => sprintf "list_refresh: %d from %s produced %d bytes.", $list->{id}, $list->{refresh_url}, length($content));
        my $entries = 0;
        # Set refresh to false
        $STH{unset_refresh}->execute($list->{id});
        foreach my $entry (split /(?:\r?\n)+/, $content) {
            $entry ||= '';
            $entry =~ s/\s*#.*//g;
            next unless length $entry;

            # Split based on commas, semi-coloons, and spaces
            my @cols = split /[\s,;]+/, $entry;
            next unless @cols;

            # The last column is the one we tend to want courtesy MDL
            my $zone = $cols[-1];

            # Path translation
            my $path = join('.', reverse split /\./, $zone);
            $path =~ s/\-/_/g;
            next if $path =~ /[^a-zA-Z0-9.\_]/; # TODO: utf8 handling

            $self->log(debug => sprintf 'list::refresh [%d] %s <-> %s', $list->{id}, $zone, $path);
            eval { $STH{refresh_entry}->execute($list->{id}, $zone, $path); };
            next if $@;
            $entries++;
            $total++;
        }
        $self->log(info => sprintf "list::refresh for list_id:%d has %d entries.", $list->{id}, $entries);
    }
    $self->log(info => sprintf "list::refresh updated %d entries.", $total);
}

__PACKAGE__->meta->make_immutable;
