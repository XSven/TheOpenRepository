package EVE::DB;

use 5.008;
use strict;
use warnings;
use ORLite         1.50 ();
use ORLite::Mirror 1.21 {
	url           => 'http://eve.no-ip.de/inc15/inc15-sqlite3-v1.db.bz2',
	maxage        => 999999999999,
	show_progress => 1,
	tables        => [ qw{
		invMarketGroups
		invMetaTypes
		invTypes
		invTypeMaterials
		invTypeReactions
		mapRegions
		mapSolarSystems
		mapSolarSystemJumps
		staStations
		staStationTypes
	} ],
};

our $VERSION = '0.01';

1;
