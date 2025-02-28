use Geo::Basic;
use Map::Leaflet 'leaf';

# for comparison: https://9revolution9.com/tools/geo/geocode/

for <032010110 032001022> {
  my $bounds = quadkey-decode $_;
  leaf.add-rectangle: $bounds<lat-min lon-min lat-max lon-max>;
}
leaf.show;

