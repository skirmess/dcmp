#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;

use lib qw(.);

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Declared;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my %const = (
        'App::DCMP::FILE_TYPE_DIRECTORY' => App::DCMP::FILE_TYPE_DIRECTORY(),
        'App::DCMP::FILE_TYPE_OTHER'     => App::DCMP::FILE_TYPE_OTHER(),
        'App::DCMP::FILE_TYPE_REGULAR'   => App::DCMP::FILE_TYPE_REGULAR(),
        'App::DCMP::FILE_TYPE_SYMLINK'   => App::DCMP::FILE_TYPE_SYMLINK(),
    );

    for my $const ( keys %const ) {
        ok( Local::Declared::declared($const), "constant $const is defined" );
        like( $const{$const}, '/ ^ [1-9] [0-9]* $ /xsm', '... is a number' );
      OTHER_CONST:
        for my $other_const ( keys %const ) {
            next OTHER_CONST if $const eq $other_const;

            isnt( $const{$const}, $const{$other_const}, "$const ($const{$const}) is not the same as $other_const ($const{$other_const})" );
        }
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
