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
use File::Spec;

use lib qw(.);

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Suffixes;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    package App::DCMP;
    use subs qw(closedir);

    package main;
    *App::DCMP::closedir = sub { return };

    my $collect_file_info = sub {
        App::DCMP::_collect_file_info(@_);
    };

    my $basedir = cwd();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        my $tmpdir = File::Spec->catdir( tempdir(), "dir${suffix_bin}" );
        mkdir $tmpdir;
        chdir $tmpdir;

        # cwd returns Unix dir separator on Windows but tempdir returns
        # Windows path separator on Windows. The error message in dcmp is
        # generated with cwd.
        $tmpdir = cwd();

        chdir $basedir;

        my $chdir = sub {
            App::DCMP::_chdir( $tmpdir, @_ );
        };

        my @dirs;

        like( exception { App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, undef, \@dirs ) }, "/ ^ \QCannot read directory $tmpdir: \E /xsm", '_iterator_dir_fs throws an exception if closedir fails' );
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
