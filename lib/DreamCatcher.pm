# ABSTRACT: DreamCatcher is a DNS Monitoring Suite
package DreamCatcher;

# VERSION

use DreamCatcher::Helpers;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;

    # Setup
    $self->secrets(['look at my horse, my horse is amazing']);
    $self->mode('development');
    $self->sessions->default_expiration(3600*24*7);

    # App Configuration
    my $config = $self->plugin( yaml_config => {
        file      => 'dreamcatcher.yml',
        stash_key => 'config',
        class     => 'YAML::XS',
    } );

    # Helpers
    $self->plugin('DreamCatcher::Helpers');

    # Configure Defaults
    $self->defaults(
        layout => 'bootstrap',
    );

    # Router
    my $r = $self->routes;
    $r->namespaces([qw(DreamCatcher::Controller)]);

    # Normal route to controller
    $r->get('/')->to('main#index');

    # Questions Module
    $r->get('/questions')->to('questions#index');

    # Server Module
    $r->get('/server')->to('server#index');
    $r->get('/server/:id')->to('server#view');

    # Conversation Module
    $r->get('/conversation')->to('conversation#index');
    $r->get('/conversation/:id')->to('conversation#view');

    # List Module
    $r->get('/list')->to('list#index');
    $r->get('/list/:id')->to('list#view');

    # Utilities Module
    $r->get('/utility')->to('utility#index');
    $r->get('/utilities')->to('utility#index');
    $r->post('/utility/reverse')->to(controller => 'Utility', action => 'reverse_lookup');
    $r->post('/utility/clients_asking')->to(controller => 'Utility', action => 'clients_asking');
    $r->get('/utility/csmap')->to(controller => 'Utility', action => 'client_server_map');
}

1;
__END__
=pod

=head1 SYNOPSIS

This is a complete DNS Monitoring Suite.  It is currently in B<alpha> status.

A libpcap based sniffer daemon listens to DNS traffic on your network.  The
conversations are recorded and analyzed to provide insight.

=head1 PREREQUISISTES

=over

=item B<Perl>

5.14.2 or better

=item B<PostgreSQL>

9.4 or better with the B<ltree> extension

=back

=head1 INSTALLATION

Installation in the works, for now try:

    perl Makefile.PL
    make

Then install the schema:

    cd sql
    ./deploy_database_schema.pl install

Configure the instance:

    cp dreamcatcher.yml.default dreamcatcher.yml
    $EDITOR dreamcatcher.yml

Configure logging:

    $EDITOR logging.conf

=head1 USAGE

Once you have the database schema and the dreamcatcher.yaml configured, run the collector:

    sudo ./bin/dreamcatcher.pl start

Now start the web application for viewing the data:

    morbo -v script/dream_catcher

=head1 SCREENSHOTS

=over

=item L<Overview Page|https://github.com/reyjrar/DreamCatcher/raw/master/examples/screenshots/0-main.png>

=item L<Viewing a Server|https://github.com/reyjrar/DreamCatcher/raw/master/examples/screenshots/1-server.png>

=item L<Recently Asked Questions|https://github.com/reyjrar/DreamCatcher/raw/master/examples/screenshots/3-questions.png>

=back

=cut
