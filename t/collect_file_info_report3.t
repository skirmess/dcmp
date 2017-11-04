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
    use subs qw(close);

    package main;

    *App::DCMP::close = sub { return };

    my $tmpdir = tempdir();
    chdir $tmpdir;

    open my $fh, '>', 'file.txt';
    print {$fh} "hello world\n";
    close $fh;

    like( exception { App::DCMP::_collect_file_info_report('file.txt') }, "/ ^ \QUnable to read file file.txt: \E /xsm", '_collect_file_info_report throws an exception if close failes' );

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
