#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::MockModule;
use Test::More 0.88;

use Encode;

use lib qw(.);

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Suffixes;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $cwd_mock = Test::MockModule->new( 'Cwd', no_auto => 1 );
    my $cwd;
    $cwd_mock->mock( 'cwd', sub { return $cwd; } );

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        $cwd = "/tmp/dir_$suffix_bin";
        is( exception { App::DCMP::_die_with_cwd('hello >%s< world') }, "hello >$cwd< world\n", '... inserts the correct dir in the string' );

        is( exception { App::DCMP::_die_with_cwd( 'a>%s<b>%s<c>%s<d', 'A', 'B' ) }, "a>$cwd<b>A<c>B<d\n", '... inserts the correct dir in the string with multiple arguments' );

        is( exception { App::DCMP::_die_with_cwd( 'a>%1$s<b>%2$s<c>%3$s<d', 'A',  'B' ) },  "a>$cwd<b>A<c>B<d\n",   '... inserts the correct dir in the string with multiple arguments (positional arguments numbered in order)' );
        is( exception { App::DCMP::_die_with_cwd( 'a>%2$s<b>%3$s<c>%1$s<d', 'A',  'B' ) },  "a>A<b>B<c>$cwd<d\n",   '... inserts the correct dir in the string with multiple arguments (positional arguments numbered out of order)' );
        is( exception { App::DCMP::_die_with_cwd( 'a>%3$s<b>%1$s<c>%2$s<d', 'A',  'B' ) },  "a>B<b>$cwd<c>A<d\n",   '... inserts the correct dir in the string with multiple arguments (positional arguments numbered out of order)' );
        is( exception { App::DCMP::_die_with_cwd( 'a>%3$s<b>%1$s<c>%2$s<d', '%s', '%C' ) }, "a>%C<b>$cwd<c>%s<d\n", '... inserts the correct dir in the string with multiple arguments (positional arguments numbered out of order with % in arguments)' );
    }

    note(q{----------------------------------------------------------});
    note('cwd = q{}');
    $cwd = q{};
    is( exception { App::DCMP::_die_with_cwd('hello >%s< world') }, "hello ><unknown>< world\n", '... inserts <unknown> if cwd() returns an empty string' );

    note(q{----------------------------------------------------------});
    note('cwd = undef');
    $cwd = undef;
    is( exception { App::DCMP::_die_with_cwd('hello >%s< world') }, "hello ><unknown>< world\n", '... inserts <unknown> if cwd() returns undef' );

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
