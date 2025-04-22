[![Actions Status](https://github.com/bduggan/raku-geo-basic/actions/workflows/linux.yml/badge.svg)](https://github.com/bduggan/raku-geo-basic/actions/workflows/linux.yml)
[![Actions Status](https://github.com/bduggan/raku-geo-basic/actions/workflows/macos.yml/badge.svg)](https://github.com/bduggan/raku-geo-basic/actions/workflows/macos.yml)

NAME
====

Geo::Basic - Basic geospatial functions

SYNOPSIS
========

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

DESCRIPTION
===========

These are a few simple utilities for doing geospatial calculations. The following functions are provided:

    * `geohash-encode` -- encode a latitude and longitude into a geohash
    * `geohash-decode` -- decode a geohash into lat/lon bounds
    * `geohash-neighbors` -- find the neighbors of a geohash
    * `quadkey-encode` -- convert a latitude and longitude to a quadkey
    * `quadkey-decode` -- convert a quadkey to lat/lon bounds
    * `haversine-km` -- calculate the distance between two points on the earth in kilometers
    * `haversine-miles` -- calculate the distance between two points on the earth in miles

The bounds returned for geohash and quadkey decoding are hashes containing the keys lat-min, lat-max, lon-min and lon-max.

FUNCTIONS
=========

### sub geohash-encode

```raku
sub geohash-encode(
    Rat(Real) :$lat,
    Rat(Real) :$lon,
    Int :$precision = 9
) returns Mu
```

Encode a latitude and longitude into a geohash

### sub geohash-decode

```raku
sub geohash-decode(
    Str $geo
) returns Hash
```

Decode a geohash into a latitude and longitude

### sub radians

```raku
sub radians(
    Real $deg
) returns Mu
```

Convert degrees to radians

### sub km-to-miles

```raku
sub km-to-miles(
    Real $km
) returns Mu
```

Convert kilometers to miles

### sub haversine-miles

```raku
sub haversine-miles(
    Real :$lat1,
    Real :$lon1,
    Real :$lat2,
    Real :$lon2
) returns Mu
```

Calculate the great circle distance in miles, using the havarsine formula

### sub haversine-km

```raku
sub haversine-km(
    Real :$lat1,
    Real :$lon1,
    Real :$lat2,
    Real :$lon2
) returns Mu
```

Calculate the great circle distance in kilometers using the havarsine formula

### sub quadkey-decode

```raku
sub quadkey-decode(
    Str $quadkey
) returns Mu
```

Convert a quadkey to lat/lon bounds

### sub quadkey-encode

```raku
sub quadkey-encode(
    Numeric :$lat,
    Numeric :$lon,
    Int :$zoom
) returns Mu
```

Convert lat/lon to quadkey

AUTHOR
======

Brian Duggan

Original geohash code by Thundergnat on Rosetta Code

