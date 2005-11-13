#!perl

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;

plan tests => 1;
$trustme = { trustme => [qr/_new$/] };
pod_coverage_ok( "Algorithm::Combinatorics", $trustme);