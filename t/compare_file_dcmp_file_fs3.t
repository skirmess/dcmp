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

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Suffixes;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    package App::DCMP;
    use subs qw(close);

    package main;
    *App::DCMP::close = sub { return };

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix = $suffix_text" ) );

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

        my @dirs;

        my $chdir = sub { App::DCMP::_chdir( File::Spec->catdir($tmpdir), @_ ) };

        my $compare_file = App::DCMP::_compare_file( $chdir, undef, \@dirs );
        is( ref $compare_file, ref sub { }, '_compare_file returns a function' );

        like( exception { $compare_file->( $file, undef, undef ) }, "/ ^ \QCannot read file $file in $tmpdir: \E /xsm", '_compare_file function throws an exception if close failes' );
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
