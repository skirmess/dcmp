#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    package App::DCMP;
    use subs qw(binmode);

    package main;

    *App::DCMP::binmode = sub { return };

    my $tmpdir = tempdir();
    chdir $tmpdir;

    open my $fh, '>', 'file.txt';
    print {$fh} "hello world\n";
    close $fh;

    like( exception { App::DCMP::_collect_file_info_report('file.txt') }, "/ ^ \Qbinmode failed for file.txt: \E /xsm", '_collect_file_info_report throws an exception if binmode failes' );

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
