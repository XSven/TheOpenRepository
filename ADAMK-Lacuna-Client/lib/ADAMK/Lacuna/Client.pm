package ADAMK::Lacuna::Client;

use 5.008;
use strict;
use warnings;
use Carp 'croak';
use Fcntl qw(:flock);
use Data::Dumper ();
use YAML::Any ();

our $VERSION = '0.01';

use constant DEBUG => 1;

use Class::XSAccessor {
  getters => [ qw(
    rpc
    uri
    name
    password
    api_key
  ) ],
  accessors => [ qw(
    debug
    session_id
    session_start
    session_timeout
    session_persistent
    cfg_file
  ) ],
};

# Base module class
use ADAMK::Lacuna::Client::Module;

require ADAMK::Lacuna::Client::RPC;
require ADAMK::Lacuna::Client::Alliance;
require ADAMK::Lacuna::Client::Body;
require ADAMK::Lacuna::Client::Buildings;
require ADAMK::Lacuna::Client::Empire;
require ADAMK::Lacuna::Client::Inbox;
require ADAMK::Lacuna::Client::Map;
require ADAMK::Lacuna::Client::Stats;

sub new {
  my $class = shift;
  my %opt   = @_;

  # Default the config file if there are no params
  if ( not %opt and -f 'lacuna.yml' ) {
    $opt{cfg_file} = 'lacuna.yml';
  }

  # Load configuration file
  if ( $opt{cfg_file} ) {
    open my $fh, '<', $opt{cfg_file}
      or croak("Could not open config file for reading: $!");
    flock($fh, LOCK_SH)
      or croak("Could not lock config file for reading: $!");
    my $yml = YAML::Any::Load( do { local $/; <$fh> } );
    close $fh;
    $opt{name}     = defined $opt{name} ? $opt{name} : $yml->{empire_name};
    $opt{password} = defined $opt{password} ? $opt{password} : $yml->{empire_password};
    $opt{uri}      = defined $opt{uri} ? $opt{uri} : $yml->{server_uri};
    foreach ( qw( uri api_key session_start session_id session_persistent ) ) {
      if ( exists $yml->{$_} ) {
        $opt{$_} = defined $opt{$_} ? $opt{$_} : $yml->{$_};
      }
    }
  }

  my @req = qw(uri name password api_key);
  croak("Need the following parameters: @req")
    if not exists $opt{uri}
       or not exists $opt{name}
       or not exists $opt{password}
       or not exists $opt{api_key};
  $opt{uri} =~ s/\/+$//;

  my $self = bless {
    session_start      => 0,
    session_id         => 0,

    # Server says it's 2h, but let's play it safe.
    session_timeout    => 3600 * 1.8,

    session_persistent => 0,
    cfg_file           => undef,
    debug              => 0,
    %opt
  } => $class;

  # The actual RPC client
  $self->{rpc} = ADAMK::Lacuna::Client::RPC->new( client => $self );

  return $self;
}

sub empire {
  ADAMK::Lacuna::Client::Empire->new( client => shift, @_ );
}

sub alliance {
  ADAMK::Lacuna::Client::Alliance->new( client => shift, @_ );
}

sub body {
  ADAMK::Lacuna::Client::Body->new( client => shift, @_ );
}

sub building {
  ADAMK::Lacuna::Client::Buildings->new( client => shift, @_ );
}

sub inbox {
  ADAMK::Lacuna::Client::Inbox->new( client => shift, @_ );
}

sub map {
  ADAMK::Lacuna::Client::Map->new( client => shift, @_ );
}

sub stats {
  ADAMK::Lacuna::Client::Stats->new( client => shift, @_ );
}

sub register_destroy_hook {
  my $self = shift;
  my $hook = shift;
  push @{$self->{destroy_hooks}}, $hook;
}

sub DESTROY {
  my $self = shift;
  if ($self->{destroy_hooks}) {
    $_->($self) for @{$self->{destroy_hooks}};
  }

  if (not $self->session_persistent) {
    $self->empire->logout;
  }
  elsif (defined $self->cfg_file) {
    $self->write_cfg;
  }
}

sub write_cfg {
  my $self = shift;
  if ($self->debug) {
    print "DEBUG: Writing configuration to disk";
  }
  croak("No config file")
    if not defined $self->cfg_file;
    my %cfg = map { ($_ => $self->{$_}) } qw(session_start
                                             session_id
                                             session_timeout
                                             session_persistent
                                             api_key);
    $cfg{server_uri}      = $self->{uri};
    $cfg{empire_name}     = $self->{name};
    $cfg{empire_password} = $self->{password};

    open my $fh, '+<', $self->{cfg_file}
      or warn("Can not write Lacuna client configuration: $!"), return();
    flock($fh, LOCK_EX) 
      or warn("Can not lock Lacuna client configuration: $!"), return();
    my $yml = YAML::Any::Dump(\%cfg);
    truncate($fh, 0);
    print $fh $yml;
    close $fh 
      or warn("Can not write Lacuna client configuration: $!"), return();
    return 1;
}

sub assert_session {
  my $self = shift;
  
  my $now = time();
  if (!$self->session_id || $now - $self->session_start > $self->session_timeout) {
    if ($self->debug) {
      print "DEBUG: Logging in since there is no session id or it timed out.\n";
    }
    my $res = $self->empire->login($self->{name}, $self->{password}, $self->{api_key});
    $self->{session_id} = $res->{session_id};
    if ($self->debug) {
      print "DEBUG: Set session id to $self->{session_id} and updated session start time.\n";
    }
  }
  elsif ($self->debug) {
      print "DEBUG: Using existing session.\n";
  }
  $self->{session_start} = $now; # update timeout
  return $self->session_id;
}

1;

__END__

=pod

=head1 NAME

ADAMK::Lacuna::Client - An RPC client for the Lacuna Expanse

=head1 SYNOPSIS

  use ADAMK::Lacuna::Client;
  my $client = ADAMK::Lacuna::Client->new(cfg_file => 'path/to/myempire.yml');
  
  # or manually:
  my $client = ADAMK::Lacuna::Client->new(
    uri      => 'https://path/to/server',
    api_key  => 'your api key here',
    name     => 'empire name',
    password => 'sekrit',
    #session_peristent => 1, # only makes sense with cfg_file set!
    #debug    => 1,
  );
  
  my $res = $client->alliance->find("The Understanding");
  my $id = $res->{alliances}->[0]->{id};
  
  use Data::Dumper;
  print Dumper $client->alliance->view_profile( $res->{alliances}->[0]->{id} );

=head1 DESCRIPTION

This module implements the Lacuna Expanse API as of 10.10.2010.

You will need to have a basic familiarity with the Lacuna RPC API
itself, so check out L<http://gameserver.lacunaexpanse.com/api/>
where C<gameserver> is the server you intend to use it on. As of this
writing, the only server is C<us1>.

The different API I<modules> are available by calling the respective
module name as a method on the client object. The returned object then
implements the various methods.

The return values of the methods are (currently) just exactly C<result> portion
of the deflated JSON responses. This is subject to change!

On failure, the methods C<croak> with a simple to parse message.
Example:

  RPC Error (1002): Empire does not exist. at ...

The number is the error code number (see API docs). The text after the colon
is the human-readable error message from the server.

You do not need to login explicitly. The client will do this on demand. It will
also handle session-timeouts and logging out for you. (Log out happens in the
destructor.)

All methods that take a session id as first argument in the
JSON-RPC API B<DO NOT REQUIRE> that you pass the session_id
manually. This is handled internally and the client will
automatically log in for you as necessary.

=head1 Methods

=head2 new

  ADAMK::Lacuna::Client->new(
    name      => 'My empire',                # empire_name in config file
    password  => 'password of the empire',   # empire_password in config file
    uri       => 'https://us1.lacunaexpanse.com/',   # server_uri in config file
    api_key   => 'public api key',
  );

=head1 CONFIGURATION FILE

Some of the parameters of the constructor can also be supplied in a
configuration file in YAML format. You can find a template in the
F<examples> subdirectory.

  empire_name: The name of my Empire
  empire_password: The password
  server_uri: https://us1.lacunaexpanse.com/

  uri:        will overwrite the server_uri key (might be a bug)
  api_key:

  session_start:
  session_id:
  session_persistent:

=head1 SEE ALSO

API docs at L<http://us1.lacunaexpanse.com/api>.

A few ready-to-use tools of varying quality live
in the F<examples> subdirectory.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
