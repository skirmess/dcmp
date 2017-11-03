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
    use subs 'readlink';

    package main;

    *App::DCMP::readlink = sub { return };

  SKIP: {
        {
            no autodie;
            skip 'The symlink function is unimplemented' if !eval { symlink q{}, q{}; 1 };
        }

        my $tmpdir = tempdir();
        chdir $tmpdir;

        symlink 'file.txt', 'link.txt';

        like( exception { App::DCMP::_collect_file_info('link.txt') }, "/ ^ \Qreadlink failed for link.txt in $tmpdir: \E /xsm", '_collect_file_info throws an exception if readlink failes' );
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
