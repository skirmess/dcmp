#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd qw(cwd);
use Encode;

use lib qw(.);

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Suffixes;
use Local::Test::Util;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    package App::DCMP;
    use subs qw(close);

    package main;
    *App::DCMP::close = sub { return };

    my $suffix_iterator = Local::Suffixes::suffix_iterator();
    my $test            = Local::Test::Util->new;

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        my $file = "file${suffix_bin}.txt";

        my $tmpdir = tempdir();
        $test->chdir($tmpdir);

        # cwd returns Unix dir separator on Windows but tempdir returns
        # Windows path separator on Windows. The error message in dcmp is
        # generated with cwd.
        $tmpdir = cwd();

        $test->touch( $file, "hello world\n" );

        like( exception { App::DCMP::_collect_file_info_dcmp_file($file) }, "/ ^ \QCannot read file $file in $tmpdir: \E /xsm", '_collect_file_info_dcmp_file throws an exception if close failes' );
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
