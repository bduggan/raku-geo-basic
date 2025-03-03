unit module Geo::Basic;

=begin pod

=head1 NAME

Geo::Basic - Basic geospatial functions

=head1 SYNOPSIS

=begin code

use Geo::Basic;
my $hash = geohash-encode lat => 51.435, lon => -0.215, precision => 5;
# "gcpue5"

my $decoded = geohash-decode $hash;
# %( lat-max => 51.416016, lat-min => 51.459961,
#    lon-max => -0.219727, lon-min => -0.175781 )

my $neighbors = geohash-neighbors $hash;
# [gcpuek gcpueh gcpudu gcpue7 gcpudg gcpue6 gcpue4 gcpudf]

my $distance-km = haversine-km :lat1(51.435), :lon1(-0.215), :lat2(51.435), :lon2(-0.214);
# 0.06931914818231608

my $distance-mi = haversine-miles :lat1(51.435), :lon1(-0.215), :lat2(51.435), :lon2(-0.214);
# 0.04307292175092216

my $quadkey = quadkey-encode 51.435, -0.215, 8;
my $bounds = quadkey-decode $quadkey;

=end code

=head1 DESCRIPTION

These are a few simple utilities for doing geospatial calculations.
The following functions are provided:

    * `geohash-encode` -- encode a latitude and longitude into a geohash
    * `geohash-decode` -- decode a geohash into a latitude and longitude
    * `geohash-neighbors` -- find the neighbors of a geohash
    * `quadkey-encode` -- convert a latitude and longitude to a quadkey
    * `quadkey-decode` -- convert a quadkey to lat/lon bounds
    * `haversine-km` -- calculate the distance between two points on the earth in kilometers
    * `haversine-miles` -- calculate the distance between two points on the earth in miles

=head1 FUNCTIONS

=end pod

# see https://rosettacode.org/wiki/Geohash#Roll_your_own
# changes: https://rosettacode.org/w/index.php?title=Geohash&diff=300667&oldid=300666
# Credit: https://rosettacode.org/wiki/User:Thundergnat
#   "Any code which I have submitted to Rosettacode may be used under the Unlicense."
#   https://choosealicense.com/licenses/unlicense/

my @Geo32 = <0 1 2 3 4 5 6 7 8 9 b c d e f g h j k m n p q r s t u v w x y z>;

#| Encode a latitude and longitude into a geohash
sub geohash-encode ( Rat(Real) :$lat, Rat(Real) :$lon, Int :$precision = 9 ) is export {
    my @coord = $lat, $lon;
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

#| Decode a geohash into a latitude and longitude
sub geohash-decode ( Str $geo --> Hash ) is export {
     my @range = [-90, 90], [-180, 180];
     my $which = 1;
     my %Geo32 = @Geo32.antipairs;
     for %Geo32{$geo.comb}».fmt('%05b').join.comb {
         @range[$which][$_] = @range[$which].sum / 2;
         $which = not $which;
     }
     my @res = @range >>*>> -1;
     my ($lat-min, $lat-max) = @res[0];
     my ($lon-min, $lon-max) = @res[1];
     %( :$lat-min, :$lat-max, :$lon-min, :$lon-max );
}

sub neighbor(Str $geo, $dx, $dy) {
  with geohash-decode($geo) {
    my $lat = ( .<lat-max> + .<lat-min> ) / 2 + $dx * (.<lat-max> - .<lat-min>);
    my $lon = ( .<lon-max> + .<lon-min> ) / 2 + $dy * (.<lon-max> - .<lon-min>);
    geohash-encode(:$lat, :$lon, precision => $geo.chars);
  }
}

# See https://eugene-eeo.github.io/blog/geohashing.html
# #| Find the neighbors of a geohash
sub geohash-neighbors( Str $geo ) is export {
  my @n;
  for <-1 0 1> X <-1 0 1> -> ($dx, $dy) {
    next if $dx == $dy == 0;
    @n.push: neighbor($geo, $dx, $dy);
  }
  @n
}

#| Convert degrees to radians
sub radians(Real $deg) is export {
  $deg * π / 180;
}

#| Convert kilometers to miles
sub km-to-miles(Real $km) is export {
  $km  / 1.609344;
}

#| Calculate the great circle distance in miles, using the havarsine formula
sub haversine-miles( Real :$lat1, Real :$lon1, Real :$lat2, Real :$lon2 ) is export {
  km-to-miles(haversine-km(:$lat1, :$lon1, :$lat2, :$lon2));
}

#| Calculate the great circle distance in kilometers using the havarsine formula
sub haversine-km(  Real :$lat1, Real :$lon1, Real :$lat2, Real :$lon2 ) is export {
  my $r = 6371; # average radius of the Earth in km
  my $dlat = radians($lat2 - $lat1);
  my $dlon = radians($lon2 - $lon1);
  my $a = sin($dlat/2) ** 2 + cos(radians($lat1)) * cos(radians($lat2)) * sin($dlon/2) ** 2;
  my $c = 2 * atan2(sqrt($a), sqrt(1-$a));
  $r * $c;
}

#| Convert a quadkey to lat/lon bounds
sub quadkey-decode(Str $quadkey) is export {
    my $zoom = $quadkey.chars;
    my ($x, $y) = (0, 0);
    
    # Convert quadkey to tile coordinates
    for $quadkey.comb -> $digit {
        $x *= 2;
        $y *= 2;
        given $digit {
            when '0' { } # NW - no adjustment needed
            when '1' { $x += 1; }  # NE
            when '2' { $y += 1; }  # SW
            when '3' { $x += 1; $y += 1; }  # SE
        }
    }
    
    # Convert tile coordinates to lat/lon bounds
    my $n = 2 ** $zoom;
    my $lon-min = $x * 360 / $n - 180;
    my $lon-max = ($x + 1) * 360 / $n - 180;
    
    # Use inverse Mercator projection for latitude
    my $lat-max = (180 / pi) * atan(sinh(pi * (1 - 2 * $y / $n)));
    my $lat-min = (180 / pi) * atan(sinh(pi * (1 - 2 * ($y + 1) / $n)));
    
    return %( :$lat-min, :$lat-max, :$lon-min, :$lon-max )
}

#| Convert lat/lon to quadkey
sub quadkey-encode(Numeric :$lat, Numeric :$lon, Int :$zoom) is export {
    # Convert lat/lon to tile coordinates
    my $lat-rad = $lat * pi / 180;
    my $n = 2 ** $zoom;
    
    # Calculate tile coordinates
    my $x = (($lon + 180) / 360) * $n;
    my $y = (1 - log(tan($lat-rad / 2 + pi / 4)) / pi) / 2 * $n;
    
    # Get integer tile coordinates
    my $tile-x = $x.floor;
    my $tile-y = $y.floor;
    
    # Ensure coordinates are within valid range
    $tile-x = (0 max $tile-x) min ($n - 1);
    $tile-y = (0 max $tile-y) min ($n - 1);
    
    # Convert to quadkey
    my $quadkey = '';
    for ^$zoom -> $i {
        # Calculate bits from most significant to least significant
        my $shift = $zoom - $i - 1;
        my $x-bit = ($tile-x +> $shift) +& 1;
        my $y-bit = ($tile-y +> $shift) +& 1;
        
        # Combine bits in proper order: y-bit determines 0/2, x-bit determines 0/1
        my $digit = ($y-bit +< 1) +| $x-bit;
        $quadkey ~= $digit;
    }
    
    return $quadkey;
}

=begin pod

=head1 AUTHOR

Brian Duggan

Original geohash code by Thundergnat on Rosetta Code

=end pod

