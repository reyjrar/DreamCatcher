package DreamCatcher::Controller::Utility;
# ABSTRACT: DreamCatcher Utility Pages
use Mojo::Base 'DreamCatcher::Controller';

sub index {
    my $self = shift;

    $self->render();
}

sub reverse_lookup {
    my $self = shift;

    my $ip = $self->param('ip');

    # Fast check for valid IP Address
    if( $ip !~ /^([0-9]{1,3}\.){3}[0-9]{1,3}$/ ) {
        $self->flash( error => "Invalid IP address passed to Utility::reverse_lookup");
        $self->redirect_to("/utility");
        return;
    }

    my %sql = (
        reverse_lookup => q{
            select
                id,
                first_ts,
                last_ts,
                name,
                type,
                class,
                value,
                reference_count
            from packet_record_answer
                where value = ?
        },
    );

    # Prepare SQL
    my $STH = $self->prepare_statements( \%sql );
    # Execute it!
    $STH->{$_}->execute($ip) for keys %{ $STH };

    $self->stash(
        ip  => $ip,
        STH => $STH,
    );

    $self->render("utility/reverse");
}

1;
