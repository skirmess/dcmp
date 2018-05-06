#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $compare_file = App::DCMP::_compare_file( undef, undef, undef );
    is( ref $compare_file, ref sub { }, '_compare_file returns a function' );

    ok( $compare_file->( undef, 'd41d8cd98f00b204e9800998ecf8427e', 'd41d8cd98f00b204e9800998ecf8427e' ), '... which returns true for identical MD5 sums' );
    ok( $compare_file->( undef, 'D41d8cd98f00b204e9800998ecf8427e', 'd41d8cd98f00b204e9800998ecf8427e' ), '... which returns true for identical MD5 sums (case insensitive)' );
    ok( !$compare_file->( undef, 'e41d8cd98f00b204e9800998ecf8427e', 'd41d8cd98f00b204e9800998ecf8427e' ), '... which returns false for different MD5 sums' );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
