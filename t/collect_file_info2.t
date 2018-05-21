#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd 'cwd';
use Encode;

use lib qw(.);

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Suffixes;
use Local::Symlink;
use Local::Test::Util;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $test = Local::Test::Util->new;

    package App::DCMP;
    use subs 'readlink';

    package main;

    *App::DCMP::readlink = sub { return; };

  SKIP: {
        skip 'The symlink function is unimplemented', 1 if !Local::Symlink::symlink_supported();

        my $suffix_iterator = Local::Suffixes::suffix_iterator();

        while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
            note(q{----------------------------------------------------------});
            note( encode( 'UTF-8', "suffix: $suffix_text" ) );

            my $dir_suffix_iterator = Local::Suffixes::suffix_iterator();

            while ( my ( $dir_suffix_text, $dir_suffix_bin ) = $dir_suffix_iterator->() ) {
                note(q{----------------------------------------------------------});
                note( encode( 'UTF-8', "dir suffix: $dir_suffix_text" ) );

                my $dir = "dir1${dir_suffix_bin}";

                my $tmpdir = tempdir();
                $test->chdir($tmpdir);

                $test->mkdir($dir);
                $test->chdir($dir);

                $tmpdir = cwd();

                my $file = "file${suffix_bin}.txt";
                my $link = "link${suffix_bin}.txt";

                $test->symlink( $file, $link );

                like( exception { App::DCMP::_collect_file_info($link) }, "/ ^ \Qreadlink failed for $link in $tmpdir: \E /xsm", '_collect_file_info throws an exception if readlink failes' );
            }
        }
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
