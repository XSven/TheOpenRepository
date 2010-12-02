#!/usr/bin/perl
#
# Script to find worlds known to you (via observatories) which are uninhabited, habitable, and in
# your range of orbits.  Ranks them and presents a summary view.  The scoring algorithm is very
# simply and probably needs work.
#
# Usage: perl colony_worlds.pl [sort]  
#  
# [sort] is 'score' by default, may also be 'distance', 'water', 'size'.  Shows in descending order.
#
# Sample output for a planet:
#
# ------------------------------------------------------------------------------
# Somestar 6            [ 123, -116] ( 10)
# Size: 33                   Colony Ship Travel Time:  1.9 hours
# Water: 5700    Short Range Colony Ship Travel Time: 83.7 hours
# ------------------------------------------------------------------------------
#   anthraci    1   bauxite 1700     beryl 1000  chalcopy 2800  chromite    1
#   fluorite    1    galena    1  goethite 2400      gold    1    gypsum 2100
#     halite    1   kerogen    1  magnetit    1   methane    1  monazite    1
#     rutile    1    sulfur    1     trona    1  uraninit    1    zircon    1
# ------------------------------------------------------------------------------
# Score:  18% [Size:  15%, Water:  14%, Ore:  25%]
# ------------------------------------------------------------------------------

use strict;
use warnings;
use Games::Lacuna::Client;
use YAML::Any ();

my $cfg_file = shift(@ARGV) || 'lacuna.yml';
unless ( $cfg_file and -e $cfg_file ) {
	die "Did not provide a config file";
}
my $sortby = shift(@ARGV) || 'score';

my $client = Games::Lacuna::Client->new(
	cfg_file => $cfg_file,
	# debug    => 1,
);

use Data::Dumper;

my %building_prereqs=(
	'Munitions Lab' => {
		'Uraninite' => 25,
		'Monazite' => 25,
	},
	'Pilot Training Facility' => {
		'Gold' => 2,
	},
	'Cloaking Lab' => {},
);
my $cond_file='colony_conditions.yml';
my $conditions={};
my @buildings;
if (-e $cond_file) {
    $conditions=YAML::Any::LoadFile($cond_file);
    if (exists $conditions->{'sort'}) {
        $sortby=$conditions->{'sort'};
    }
    if (exists $conditions->{'buildings'}) {
        foreach my $building (@{$conditions->{'buildings'}}) {
            die "Building '$building' not found in list" if !exists $building_prereqs{$building};
            next if $building_prereqs{$building} eq '' || keys %{$building_prereqs{$building}} == 0;
            push @buildings, $building;
        }
    }
}

my $data = $client->empire->view_species_stats();

# Get orbits
my $min_orbit = $data->{species}->{min_orbit};
my $max_orbit = $data->{species}->{max_orbit};

# Get planets
my $planets        = $data->{status}->{empire}->{planets};
my $home_planet_id = $data->{status}->{empire}->{home_planet_id}; 
my ($hx,$hy)       = @{$client->body(id => $home_planet_id)->get_status()->{body}}{'x','y'};

# Get obervatories;
my @observatories;
for my $pid (keys %$planets) {
    my $buildings = $client->body(id => $pid)->get_buildings()->{buildings};
    push @observatories, grep { $buildings->{$_}->{url} eq '/observatory' } keys %$buildings;
}

print "Orbits: $min_orbit through $max_orbit\n";
print "Observatory IDs: ".join(q{, },@observatories)."\n";

# Find stars
my @stars;
for my $obs_id (@observatories) {
    push @stars, @{$client->building( id => $obs_id, type => 'Observatory' )->get_probed_stars()->{stars}};
}

# Gather planet data
my @planets;
for my $star (@stars) {
    push @planets, grep { (not defined $_->{empire}) && $_->{orbit} >= $min_orbit && $_->{orbit} <= $max_orbit && $_->{type} eq 'habitable planet' } @{$star->{bodies}};
}

# Calculate some planet metadata
for my $p (@planets) {
    $p->{distance} = sqrt(($hx - $p->{x})**2 + ($hy - $p->{y})**2);
    $p->{water_score} = ($p->{water} - 5000) / 50;
    $p->{size_score}  = (($p->{size} > 50 ? 50 : $p->{size} ) - 30) * 5;
    $p->{ore_score}   = (scalar grep { $p->{ore}->{$_} > 1 } keys %{$p->{ore}}) * 5;
    $p->{score}       = ($p->{water_score}+$p->{size_score}+$p->{ore_score})/3;
}

# Sort and print results
PLANET: for my $p (sort { $b->{$sortby} <=> $a->{$sortby} } @planets) {
    foreach my $building (@buildings) {
        my $prereqs=$building_prereqs{$building};
        my $ore_available=0;
        while (my ($ore, $quantity) = each %$prereqs) {
            $ore_available++ if ($p->{ore}{lc $ore} >= $quantity);
        }
        next PLANET unless $ore_available;
    }
    my $d = $p->{distance};
    print_bar();
    printf "%-20s [%4s,%4s] (Distance: %3s)\nSize: %2d                   Colony Ship Travel Time:  %3.1f hours\nWater: %4d    Short Range Colony Ship Travel Time: %3.1f hours\n",
        $p->{name},$p->{x},$p->{y},int($d),$p->{size},($d/5.23),$p->{water},($d/.12);
    print_bar();
    for my $ore (sort keys %{$p->{ore}}) {
        printf "  %8s %4d",substr($ore,0,8),$p->{ore}->{$ore};
        if ($ore eq 'chromite' or $ore eq 'gypsum' or $ore eq 'monazite' or $ore eq 'zircon') {
            print "\n";
        }
    }
    print_bar();
    printf "Score: %3d%% [Size: %3d%%, Water: %3d%%, Ore: %3d%%]\n",@{$p}{'score','size_score','water_score','ore_score'};
    print_bar();
    print "\n"
}

sub print_bar {
    print "-" x 78;
    print "\n";
}

