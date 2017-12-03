#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Encode;
use File::Spec;

use lib qw(.);

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Suffixes;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    package App::DCMP;
    use subs qw(binmode);

    package main;
    *App::DCMP::binmode = sub { return };

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix = $suffix_text" ) );

        my $file = "file${suffix_bin}.txt";

        my $tmpdir = tempdir();
        chdir $tmpdir;

        open my $fh, '>', $file;
        print {$fh} "hello world\n";
        close $fh;

        my @dirs;

        my $chdir = sub { App::DCMP::_chdir( File::Spec->catdir($tmpdir), @_ ) };

        like( exception { App::DCMP::_compare_file_dcmp_file_fs( $chdir, \@dirs, $file, undef, undef ) }, "/ ^ \Qbinmode failed for $file in $tmpdir: \E /xsm", '_collect_file_info_dcmp_file throws an exception if binmode failes' );
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
