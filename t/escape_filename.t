#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More 0.88;

use Encode;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    like( exception { App::DCMP::_escape_filename("\x{20ac}") }, "/\Qinternal error: _escape_filename cannot encode Unicode text strings\E/xsm", '_escape_filename() throws an error if you try to encode a Unicode text string' );
    is( App::DCMP::_escape_filename(undef), undef, '_escape_filename() returns under if the argument is undef' );
    is( App::DCMP::_escape_filename(),      undef, '... or not given' );

    my %test = (
        'helloworld'           => 'helloworld',
        "hello\tworld"         => 'hello%09world',
        'hello world'          => 'hello%20world',
        "h e l l o\nw o r l d" => 'h%20e%20l%20l%20o%0Aw%20o%20r%20l%20d',
        q{}                    => q{},
    );

    for my $i ( 0 .. 255 ) {
        my $name = 'chr~' . chr($i) . q{~};
        $test{$name} = sprintf 'chr~%%%02X~', $i;
    }

    for my $i ( 'A' .. 'Z', 'a' .. 'z', '0' .. '9', qw(. _ ~ -) ) {
        my $name = 'chr~' . $i . q{~};
        $test{$name} = $name;
    }

    for my $test_input ( sort keys %test ) {
        my $test_result = $test{$test_input};
        is( App::DCMP::_escape_filename($test_input), $test_result, "=> $test_result" );
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
