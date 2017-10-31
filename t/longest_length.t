#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    is( App::DCMP::_longest_length(), 0, '_longest_length() returns 0 for no elements' );

    my @strings = (q{});
    is( App::DCMP::_longest_length(@strings), 0, '_longest_length() returns 0 for a single zero size element' );
    push @strings, q{};
    is( App::DCMP::_longest_length(@strings), 0, '_longest_length() returns 0 for two zero size element' );

    @strings = qw(a);
    is( App::DCMP::_longest_length(@strings), 1, '_longest_length() returns 1 for a single one character string element' );

    @strings = qw(a bb ccc dddd eeeee ffff ggg hh ii j);
    is( App::DCMP::_longest_length(@strings), 5, '_longest_length() returns 5 for multiple elements' );
    @strings = qw(a bb ccc dddd eeeee ffff ggg hh ii j kkkkk);
    is( App::DCMP::_longest_length(@strings), 5, '_longest_length() returns 5 for multiple elements' );

    @strings = qw(a bb ccc dddd eeeee ffff ggg hh ii j kkkkkk);
    is( App::DCMP::_longest_length(@strings), 6, '_longest_length() returns 6 for multiple elements' );

    @strings = qw(zzzzzzz a bb ccc dddd eeeee ffff ggg hh ii j kkkkkk);
    is( App::DCMP::_longest_length(@strings), 7, '_longest_length() returns 7 for multiple elements' );

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl

