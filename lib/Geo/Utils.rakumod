unit module Geo::Utils;

# see https://rosettacode.org/wiki/Geohash#Roll_your_own
# changes: https://rosettacode.org/w/index.php?title=Geohash&diff=300667&oldid=300666
# Credit: https://rosettacode.org/wiki/User:Thundergnat
#   "Any code which I have submitted to Rosettacode may be used under the Unlicense."
#   https://choosealicense.com/licenses/unlicense/

my @Geo32 = <0 1 2 3 4 5 6 7 8 9 b c d e f g h j k m n p q r s t u v w x y z>;

sub geohash-encode ( Rat(Real) $latitude, Rat(Real) $longitude, Int $precision = 9 ) is export {
    my @coord = $latitude, $longitude;
    my @range = [-90, 90], [-180, 180];
    my $which = 1;
    my $value = '';
    while $value.chars < $precision * 5 {
        my $mid = @range[$which].sum / 2;
        $value ~= my $upper = +(@coord[$which] > $mid);
        @range[$which][not $upper] = $mid;
        $which = not $which;
    }
    @Geo32[$value.comb(5)».parse-base(2)].join;
}

sub geohash-decode ( Str $geo ) is export {
     my @range = [-90, 90], [-180, 180];
     my $which = 1;
     my %Geo32 = @Geo32.antipairs;
     for %Geo32{$geo.comb}».fmt('%05b').join.comb {
         @range[$which][$_] = @range[$which].sum / 2;
         $which = not $which;
     }
     @range >>*>> -1
}

sub neighbor(Str $geo, $dx, $dy) {
  my $d = geohash-decode($geo);
  my ($max-lat, $min-lat) = @($d[0]);
  my ($max-lon, $min-lon) = @($d[1]);
  my $new-lat = ( $max-lat + $min-lat ) / 2 + $dx * ($max-lat - $min-lat);
  my $new-lon = ( $max-lon + $min-lon ) / 2 + $dy * ($max-lon - $min-lon);
  geohash-encode($new-lat, $new-lon);
}

# See https://eugene-eeo.github.io/blog/geohashing.html
sub geohash-neighbors( Str $geo ) is export {
  my @n;
  for <-1 0 1> X <-1 0 1> -> ($dx, $dy) {
    next if $dx == $dy == 0;
    @n.push: neighbor($geo, $dx, $dy);
  }
  @n
}
