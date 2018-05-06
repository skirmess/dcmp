#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    is( App::DCMP::_unescape_filename(undef), undef, '_unescape_filename() returns under if the arfument is undef' );
    is( App::DCMP::_unescape_filename(),      undef, '... or not given' );

    my %test = (
        'helloworld'                            => 'helloworld',
        'hello%09world'                         => "hello\tworld",
        'hello%20world'                         => 'hello world',
        'h%20e%20l%20l%20o%0Aw%20o%20r%20l%20d' => "h e l l o\nw o r l d",
        q{}                                     => q{},
    );

    for my $i ( 0 .. 255 ) {
        my $input = sprintf 'chr[%%%02X]', $i;
        $test{$input} = 'chr[' . chr($i) . ']';
    }

    for my $test_input ( sort keys %test ) {
        my $test_result = $test{$test_input};
        is( App::DCMP::_unescape_filename($test_input), $test_result, "=> $test_input" );
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
