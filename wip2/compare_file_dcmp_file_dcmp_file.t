#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    ok( App::DCMP::_compare_file_dcmp_file_dcmp_file( undef, undef, 'd41d8cd98f00b204e9800998ecf8427e', 'd41d8cd98f00b204e9800998ecf8427e' ), '_compare_file_dcmp_file_dcmp_file returns true for identical MD5 sums' );
    ok( App::DCMP::_compare_file_dcmp_file_dcmp_file( undef, undef, 'D41d8cd98f00b204e9800998ecf8427e', 'd41d8cd98f00b204e9800998ecf8427e' ), '_compare_file_dcmp_file_dcmp_file returns true for identical MD5 sums (case insensitive)' );
    ok( !App::DCMP::_compare_file_dcmp_file_dcmp_file( undef, undef, 'e41d8cd98f00b204e9800998ecf8427e', 'd41d8cd98f00b204e9800998ecf8427e' ), '_compare_file_dcmp_file_dcmp_file returns false for different MD5 sums' );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
