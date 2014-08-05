#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;

# Add local lib path
use lib "$FindBin::Bin/../lib";

use File::Spec;
use File::Basename;
use File::Slurp qw( slurp );
use YAML;
use DBI;

#------------------------------------------------------------------------#
# Grab Mode
my %OPTIONS = ();
my %MODES = (
    install => sub { 1 },
    upgrade =>  sub {
        my $upgrade_from = shift @ARGV;
        if( !$upgrade_from ) {
            die "usage: $0 upgrade VERSION_TO_START_FROM\n";
        }
        $OPTIONS{upgrade_from} = $upgrade_from;
    },
);
my $MODE = shift @ARGV;
$MODE //= 'install';

if( !exists $MODES{$MODE} ) {
    die "usage: $0 [mode: " . join(',', keys %MODES) . "]\n";
}
# Do Argument Check
$MODES{$MODE}->();

#------------------------------------------------------------------------#
# Locate all the necessary directories
my @BasePath = File::Spec->splitdir( $FindBin::Bin );
pop @BasePath;

#------------------------------------------------------------------------#
# Load Configuration
my $configFile = File::Spec->catfile( @BasePath, 'dreamcatcher.yml' );
my $CFG = YAML::LoadFile( $configFile ) or die "unable to load $configFile: $!\n";


#------------------------------------------------------------------------#
# Load Schema YAML
my $deployFile = File::Spec->catfile( @BasePath, 'sql', 'schema', 'deploy.yml' );
my $SCHEMA = YAML::LoadFile( $deployFile ) or die "unable to load $deployFile: $!\n";

# Connect to the Database:
my $dbConn = DBI->connect( $CFG->{db}{dsn}, $CFG->{db}{user}, $CFG->{db}{pass},
    {PrintError => 0, RaiseError => 1} );

if( $MODE eq 'install' ) {
    install( $SCHEMA->{install} );
    if( exists $SCHEMA->{upgrade} and ref $SCHEMA->{upgrade} eq 'HASH' ) {
        foreach my $version ( sort keys %{ $SCHEMA->{upgrade} } ) {
            upgrade( $SCHEMA->{upgrade}{$version}, $version );
        }
    }
}
elsif( $MODE eq 'upgrade' ) {
    if ( !exists $SCHEMA->{upgrade}{$OPTIONS{upgrade_from}} ) {
        my $upgrades = join(", ", keys %{ $SCHEMA->{upgrade} });
        die "Unknown upgrade starting point, valid options are:\n - $upgrades\n";
    }
    foreach my $version ( sort keys %{ $SCHEMA->{upgrade} } ) {
        next unless $version >= $OPTIONS{upgrade_from};
        upgrade( $SCHEMA->{upgrade}{$version}, $version );
    }
}


sub install {
    my $schema = shift;

    # Install Base
    foreach my $entity (@{ $schema->{base} } ) {
        my $srcFile = File::Spec->catfile( @BasePath, qw(sql schema install base), "$entity.sql" );
        die "$srcFile does not exist!\n" unless -f $srcFile;

        my $sql = slurp( $srcFile );
        my $rc = eval {
            $dbConn->do($sql);
            1;
        };
        my $error = defined $rc && $rc == 1 ? undef : $@;

        if (!defined($error) ) {
            print " - applied base $entity!\n";
        }
        elsif ( $error  =~ /relation \"$entity\" already exists/ ) {
            print " - base $entity already exists!\n";
        }
        else {
            die " - applying base $entity failed with error: $error\n";
        }
    }

    # Install Plugins
    foreach my $plugin (sort { $schema->{plugins}{$a}{level} <=> $schema->{plugins}{$b}{level} } keys %{ $schema->{plugins} } ) {
        my $plugin_pathpart = $plugin;
        $plugin_pathpart =~ s/\:\:/_/g;
        my @path = ( @BasePath, qw( sql schema install plugins ), $plugin_pathpart );
        print "+ Processing plugin $plugin:\n";
        foreach my $entity ( @{ $schema->{plugins}{$plugin}{entities} } ) {
            my $srcFile = File::Spec->catfile( @path, "$entity.sql" );
            die "$srcFile does not exist!\n" unless -f $srcFile;

            my $sql = slurp( $srcFile );
            my $rc = eval {
                $dbConn->do($sql);
                1;
            };
            my $error = defined $rc && $rc == 1 ? undef : $@;

            if (!defined $error ) {
                print " - applied plugin($plugin) $entity!\n";
            }
            elsif ( $error  =~ /relation \"$entity\" already exists/ ) {
                print " - plugin($plugin) $entity already exists!\n";
            }
            else {
                die " - applying plugin($plugin) $entity failed with error: $error\n";
            }
        }
    }
}

sub upgrade {
    my ($schema,$ver) = @_;

    print "\nApplying upgrade $ver..\n";

    if( exists $schema->{base} ) {
        # Upgrade Base
        print " Processing base.. \n";
        foreach my $entity (@{ $schema->{base} } ) {
            my $srcFile = File::Spec->catfile( @BasePath, qw(sql schema upgrade), $ver, 'base', "$entity.sql" );
            die " !! $srcFile does not exist!\n" unless -f $srcFile;

            my $sql = slurp( $srcFile );
            my $rc = eval {
                $dbConn->do($sql);
                1;
            };
            my $error = defined $rc && $rc == 1 ? undef : $@;
            die "  - applying base $entity failed with error: $error\n" if $error;
            print "  - applied base $entity!\n";
        }
    }

    if( exists $schema->{plugins} ) {
        # Upgrade Plugins
        foreach my $plugin (sort { $schema->{plugins}{$a}{level} <=> $schema->{plugins}{$b}{level} } keys %{ $schema->{plugins} } ) {
            my $plugin_pathpart = $plugin;
            $plugin_pathpart =~ s/\:\:/_/g;
            my @path = ( @BasePath, qw( sql schema upgrade ), $ver,  'plugins', $plugin_pathpart );
            print " + Processing plugin $plugin:\n";
            foreach my $entity ( @{ $schema->{plugins}{$plugin}{entities} } ) {
                my $srcFile = File::Spec->catfile( @path, "$entity.sql" );
                die "  !! $srcFile does not exist!\n" unless -f $srcFile;

                my $sql = slurp( $srcFile );
                my $rc = eval {
                    $dbConn->do($sql);
                    1;
                };
                my $error = defined $rc && $rc == 1 ? undef : $@;
                die "  - applying plugin($plugin) $entity failed with error: $error\n" if $error;
                print "  - applied plugin($plugin) $entity!\n";

            }
        }
    }
}
