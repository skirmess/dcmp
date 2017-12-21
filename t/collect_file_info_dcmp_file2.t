#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd qw(cwd);
use Encode;

use lib qw(.);

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Suffixes;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    package App::DCMP;
    use subs qw(binmode);

    package main;
    *App::DCMP::binmode = sub { return };

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        my $file = "file${suffix_bin}.txt";

        my $tmpdir = tempdir();
        chdir $tmpdir;

        # cwd returns Unix dir separator on Windows but tempdir returns
        # Windows path separator on Windows. The error message in dcmp is
        # generated with cwd.
        $tmpdir = cwd();

        open my $fh, '>', $file;
        print {$fh} "hello world\n";
        close $fh;

        like( exception { App::DCMP::_collect_file_info_dcmp_file($file) }, "/ ^ \Qbinmode failed for $file in $tmpdir: \E /xsm", '_collect_file_info_dcmp_file throws an exception if binmode failes' );
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl