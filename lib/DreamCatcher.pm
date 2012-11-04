# ABSTRACT: DreamCatcher is a DNS Monitoring Suite
package DreamCatcher;

our $VERSION = 0.1;

use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Setup
    $self->secret('look at my horse, my horse is amazing');
    $self->mode('development');
    $self->sessions->default_expiration(3600*24*7);

    # App Configuration
    my $config = $self->plugin( yaml_config => {
        file      => 'dreamcatcher.yml',
        stash_key => 'config',
        class     => 'YAML::XS',
    } );

    # Configure Defaults
    $self->defaults(
        layout => 'bootstrap',
    );

    # Router
    my $r = $self->routes;
    $r->namespace("DreamCatcher::Controller");

    # Normal route to controller
    $r->get('/')->to('main#index');

    # Questions Module
    $r->get('/questions')->to('questions#index');

    # Server Module
    $r->get('/server')->to('server#index');
    $r->get('/server/:id')->to('server#view');
}

1;
__END__
=head1 SYNOPSIS

This is a complete DNS Monitoring Suite.  It is currently in B<alpha> status.

=head1 INSTALLATION

Installation in the works, for now try:

   perl Makefile.PL
   make

=head1 USAGE

Currently the sniffer does not work.  It is possible to use this project in conjunction with
the L<DNS Monitor|https://github.com/reyjrar/dns-monitor> as the databases are compatible.

Once you have the dns-monitor sniffer and analyzer running, you can startup the DreamCatcher front
end using:

    morbo -v script/dream_catcher

=head1 SCREENSHOTS

=over

=item L<Overview Page|https://github.com/reyjrar/DreamCatcher/raw/master/examples/screenshots/0-main.png>

=item L<Viewing a Server|https://github.com/reyjrar/DreamCatcher/raw/master/examples/screenshots/1-server.png>

=item L<Recently Asked Questions|https://github.com/reyjrar/DreamCatcher/raw/master/examples/screenshots/3-questions.png>

=back

=end html

=cut
