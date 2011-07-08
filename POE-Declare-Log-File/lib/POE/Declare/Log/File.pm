package POE::Declare::Log::File;

=pod

=head1 NAME

POE::Declare::Log::File - A simple HTTP client based on POE::Declare

=head1 SYNOPSIS

    # Create the web server
    my $http = POE::Declare::Log::File->new(
        File => '/var/log/my.log',
    );
    
    # Control with methods
    $http->start;
    $http->GET('http://google.com');
    $http->stop;

=head1 DESCRIPTION

This module provides a simple logging module which spools output to a file,
queueing and batching messages in memory if the message rate exceeds the
responsiveness of the filesystem.

The implemenetation is intentionally minimalist and has no dependencies beyond
those of L<POE::Declare> itself, which makes this module useful for simple
utility logging or debugging systems.

=head1 METHODS

=cut

use 5.008;
use strict;
use Carp                  ();
use Symbol                ();
use POE             1.293 ();
use POE::Wheel::ReadWrite ();

our $VERSION = '0.01';

use POE::Declare 0.54 {
	Filename      => 'Param',
	Handle        => 'Param',
	ErrorEvent    => 'Message',
	ShutdownEvent => 'Message',
	wheel         => 'Internal',
	queue         => 'Internal',
	state         => 'Internal',
};





######################################################################
# Constructor and Accessors

=pod

=head2 new

    my $server = POE::Declare::Log::File->new(
        Filename      => 
        ShutdownEvent => \&on_shutdown,
    );

The C<new> constructor sets up a reusable HTTP client that can be enabled
and disabled repeatedly as needed.

=cut

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	# Open the file if needed
	if ( $self->Filename and not $self->Handle ) {
		my $filename = $self->Filename;
		my $handle   = Symbol::gensym();
		if ( open( $handle, '>>', $filename ) ) {
			$self->{Handle} = $handle;
		} else {
			Carp::croak("Failed to open $filename");
		}
	}
	unless ( $self->Handle ) {
		Carp::croak("Did not provide a Filename or Handle param");
	}

	# Create the message queue
	$self->{state} = 'STOP';
	$self->{queue} = [ ];
	$self->{wheel} = undef;

	return $self;
}





######################################################################
# Control Methods

=pod

=head2 start

The C<start> method enables the web server. If the server is already running,
this method will shortcut and do nothing.

If called before L<POE> has been started, the web server will start
immediately once L<POE> is running.

=cut

sub start {
	my $self = shift;
	unless ( $self->spawned ) {
		$self->spawn;
		$self->post('startup');
	}
	return 1;
}

=pod

=head2 stop

The C<stop> method disables the web server. If the server is not running,
this method will shortcut and do nothing.

=cut

sub stop {
	my $self = shift;
	if ( $self->spawned ) {
		$self->post('shutdown');
	}
	return 1;
}

=pod

=head2 print

    $log->print("This is a log message");

Writes one or more messages to the log.

Returns true if the message will be flushed to the file immediately, false if
the message will be queued for later dispatch, or C<undef> if the logger is
disabled and the message will be dropped.

=cut

sub print {
	my $self = shift;

	# Has something gone wrong and we shouldn't queue?
	unless ( $self->{queue} ) {
		return;
	}

	# Add any messages to the queue of pending output
	push @{$self->{queue}}, @_;

	# Initiate a flush event if we aren't doing one already
	if ( $self->{state} eq 'IDLE' ) {
		$self->post('flush');
		return 1;
	}

	# Message is delayed
	return 0;
}





######################################################################
# Event Methods

sub startup : Event {
	# Create the read/write wheel on the filehandle
	$_[SELF]->{wheel} = POE::Wheel::ReadWrite->new(
		Handle       => $_[SELF]->Handle,
		FlushedEvent => 'flush',
		ErrorEvent   => 'error',
	);

	# Do an initial queue flush if we have anything
	if ( @{$_[SELF]->{queue}} ) {
		$_[SELF]->call('flush');
	}

	return;
}

sub flush : Event {
	if ( scalar @{$_[SELF]->{queue}} ) {
		if ( $_[SELF]->{state} eq 'IDLE' ) {
			$_[SELF]->{state} = 'BUSY';
		}

		# Merge the queued messages ourself to prevent having to use a heavier
		# POE line filter in the Read/Write wheel.
		$_[SELF]->{wheel}->put(
			join("\n", @{$_[SELF]->{queue}}) . "\n"
		);
		$_[SELF]->{queue} = [ ];

	} else {
		# Nothing (left) to do
		if ( $_[SELF]->{state} eq 'HALT' ) {
			$_[SELF]->{state} = 'STOP';
			$_[SELF]->finish;
			$_[SELF]->Shutdown;

		} else {
			$_[SELF]->{state} = 'IDLE';
		}
	}

	return;
}

sub error : Event {
	$_[SELF]->{state} = 'CRASH';

	# Prevent additional message and flush queue
	$_[SELF]->{queue} = undef;

	# Clean up streaming resources
	$_[SELF]->clean;

	return;
}

sub shutdown : Event {
	# Superfluous crash shutdown
	if ( $_[SELF]->{state} eq 'CRASH' ) {
		$_[SELF]->finish;
		$_[SELF]->Shutdown;
		return;
	}

	# Shutdown with nothing pending to write
	if ( $_[SELF]->{state} eq 'IDLE' ) {
		$_[SELF]->{state} = 'STOP';
		$_[SELF]->finish;
		$_[SELF]->Shutdown;
		return;
	}

	# Shutdown while writing
	if ( $_[SELF]->{state} eq 'BUSY' ) {
		# Signal we want to stop as soon as the queue is empty,
		# but otherwise just wait for the natural end.
		$_[SELF]->{state} = 'HALT';
		return;
	}

	# Must be a shutdown while HALT, just keep waiting
	return;
}





######################################################################
# POE::Declare::Object Methods

sub finish {
	my $self = shift;

	# Clean up streaming resources
	$self->clean;

	# Pass through as normal
	$self->SUPER::finish(@_);
}

sub clean {
	my $self = shift;

	# Shutdown the wheel
	$_[SELF]->{wheel}->shutdown_output;
	$_[SELF]->{wheel} = undef;

	# If we opened a file, close it
	if ( $self->Filename and $self->{Handle} ) {
		close delete $self->{Handle};
	}

	return;
}

compile;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Declare-Log-File>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<POE::Declare>, L<POE>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut