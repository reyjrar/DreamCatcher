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
