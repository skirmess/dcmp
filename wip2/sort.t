#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;

use Encode;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    note('zero items');
    my @input;
    my @output = App::DCMP::_sort(@input);
    is( scalar @output, 0, '_sort returns an empty list' );

    note('one item');
    push @input, 'a';
    @output = App::DCMP::_sort(@input);
    is( scalar @output, 1,   '_sort returns one item' );
    is( $output[0],     'a', '... which is the correct one' );

    note('two items');
    push @input, 'b';
    @output = App::DCMP::_sort(@input);
    is( scalar @output, 2,   '_sort returns two items' );
    is( $output[0],     'a', '... first one is the correct one' );
    is( $output[1],     'b', '... second one is the correct one' );

    note('non alphanumeric input');

    my @files = (

        # UTF-8 encoded "Latin Capital Letter a with Grave"
        [ 3, encode( 'UTF-8', "A\x{00C0}ad" ) ],

        # euro sign as UTF-8
        [ 1, encode( 'UTF-8', "A\x{20ac}ab" ) ],

        # "Latin Capital Letter a with Grave" as Latin-1, which is an invalid UTF-8 char
        [ 2, "A\x{00C0}ac" ],

        [ 5, "A\naf" ],

        # UTF-8 encoded "Latin Capital Letter a with Grave" in decomposed form
        [ 4, encode( 'UTF-8', "\x{0041}\x{0300}ae" ) ],

        [ 0, 'Aaa' ],
    );

    @input = map { $_->[1] } @files;

    my @expected = map { $_->[1] } sort { $a->[0] <=> $b->[0] } @files;

    @output = App::DCMP::_sort(@input);
    is( scalar @output, 6, '_sort returns six items' );

    is_deeply( \@output, \@expected, '... in the correct order' );

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
