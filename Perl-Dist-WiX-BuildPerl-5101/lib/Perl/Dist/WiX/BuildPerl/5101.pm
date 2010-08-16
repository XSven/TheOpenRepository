package Perl::Dist::WiX::BuildPerl::5101;

=pod

=begin readme text

Perl::Dist::WiX::BuildPerl::5101 version 1.250_100

=end readme

=for readme stop

=head1 NAME

Perl::Dist::WiX::BuildPerl::5101 - Files and code for building perl 5.10.1

=head1 VERSION

This document describes Perl::Dist::WiX::BuildPerl::5101 version 1.250_100.

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 DESCRIPTION

This module provides the routines that Perl::Dist::WiX uses in order to
build Perl itself.  

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.
	# See Perl::Dist::WiX::BuildPerl::PluginInterface for more information.

=cut
	
use 5.010;
use Moose::Role;
use Perl::Dist::WiX::Asset::Perl qw();
use File::ShareDir qw();

our $VERSION = '1.250_100';
$VERSION =~ s/_//sm;



around install_perl_plugin => sub {
	shift;
	my $self = shift;

	# Check for an error in the object.
	f ( not $self->bin_make() ) {
		PDWiX->throw('Cannot build Perl yet, no bin_make defined');
	}

	# Get the information required for Perl's toolchain.
	my $toolchain = $self->_create_perl_toolchain();

	# Install perl.
	my $perl = Perl::Dist::WiX::Asset::Perl->new(
		parent    => $self,
		url       => 'http://strawberryperl.com/package/perl-5.10.1.tar.gz',
		toolchain => $toolchain,
		patch     => [ qw{
			  lib/CPAN/Config.pm
			  win32/config.gc
			  win32/config_sh.PL
			  win32/config_H.gc
			  }
		],
		license => {
			'perl-5.10.1/Readme'   => 'perl/Readme',
			'perl-5.10.1/Artistic' => 'perl/Artistic',
			'perl-5.10.1/Copying'  => 'perl/Copying',
		},
	);
	$perl->install();

	# Should have a perl to use now.
	$self->_set_bin_perl( $self->file(qw/perl bin perl.exe/) );

	# Create the site/bin path so we can add it to the PATH.
	$self->make_path( $self->dir( qw(perl site bin) ) );

	# Add to the environment variables
	$self->add_path( qw(perl site bin) );
	$self->add_path( qw(perl bin) );

	return 1;
} ## end sub install_perl_plugin



around '_find_perl_file' => sub {
	my $orig = shift;
	my $self = shift;
	my $file = shift;
	
	my $location = undef;

	# Allow portability overrides if required.
	if ($self->portable()) {
		$location = eval { 
			File::ShareDir::module_file('Perl::Dist::WiX::BuildPerl::5101', "portable/$file");
		};
		
		if ($location) {
			return $location;
		}
	}
	
	$location = eval { 
		File::ShareDir::module_file('Perl::Dist::WiX::BuildPerl::5101', "default/$file");
	};
	
	if ($location) {
		return $location;
	} else {
		return $self->$orig($file);
	}
};

# Set the things that are defined by the perl version.

has 'perl_version_literal' => (
	is       => 'ro',
	init_arg => undef,
	default => '5.010001',
);

has 'perl_version_human' => (
	is       => 'ro',
	writer   => '_set_perl_version_human',
	init_arg => undef,
	default => '5.10.1',
);

has '_perl_version_arrayref' => (
	is       => 'ro',
	init_arg => undef,
	default => sub {[5, 10, 1]},
);

has '_perl_bincompat_version_arrayref' => (
	is       => 'ro',
	init_arg => undef,
	default => sub {[5, 10, 0]},
);

has '_is_git_snapshot' => (
	is       => 'ro',
	init_arg => undef,
	default => '',
);

no Moose::Role;
1;

__END__

=pod

=head1 DIAGNOSTICS

This module does not throw exceptions.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=for readme continue

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=for readme stop

=cut