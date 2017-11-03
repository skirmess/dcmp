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

    my %const = (
        'App::DCMP::FILE_TYPE_DIRECTORY' => App::DCMP::FILE_TYPE_DIRECTORY(),
        'App::DCMP::FILE_TYPE_OTHER'     => App::DCMP::FILE_TYPE_OTHER(),
        'App::DCMP::FILE_TYPE_REGULAR'   => App::DCMP::FILE_TYPE_REGULAR(),
        'App::DCMP::FILE_TYPE_SYMLINK'   => App::DCMP::FILE_TYPE_SYMLINK(),
    );

    for my $const ( keys %const ) {
        ok( declared($const), "constant $const is defined" );
        like( $const{$const}, '/ ^ [0-9] + $ /xsm', '... is a number' );
      OTHER_CONST:
        for my $other_const ( keys %const ) {
            next OTHER_CONST if $const eq $other_const;

            isnt( $const{$const}, $const{$other_const}, "$const ($const{$const}) is not the same as $other_const ($const{$other_const})" );
        }
    }

    done_testing();

    exit 0;
}

# copied from 'perldoc constant'
sub declared ($) {
    use constant 1.01;    # don't omit this!
    my $name = shift;
    $name =~ s/^::/main::/;
    my $pkg = caller;
    my $full_name = $name =~ /::/ ? $name : "${pkg}::$name";
    $constant::declared{$full_name};
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
