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

    my %test = (
        'helloworld'           => 'helloworld',
        "hello\tworld"         => 'hello%09world',
        'hello world'          => 'hello%20world',
        "h e l l o\nw o r l d" => 'h%20e%20l%20l%20o%0Aw%20o%20r%20l%20d',
        "\x{20ac}"             => "\x{20ac}",
        "\x{00C0}"             => "\x{00C0}",
        "\x{0041}\x{0300}"     => "\x{0041}\x{0300}",
        q{}                    => q{},
    );

    for my $i ( 0 .. 255 ) {
        my $name = 'chr[' . chr($i) . ']';
        $test{$name} = $name;
    }

    for my $i ( 0 .. 0x20, 0x25, 0x7F ) {
        my $name = 'chr[' . chr($i) . ']';
        my $result = sprintf 'chr[%%%02X]', $i;
        $test{$name} = $result;
    }

    for my $test_key ( sort keys %test ) {
        my $test_result = $test{$test_key};
        is( App::DCMP::_escape_filename($test_key), $test_result, encode( 'UTF-8', "File name: $test_result" ) );
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
