#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Encode;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    package App::DCMP;
    use subs qw(binmode);

    package main;

    *App::DCMP::binmode = sub { return };

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, "a\nb";
    }

    for my $suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix" ) );

        my $file = "file${suffix}.txt";
        my $file_utf8 = encode( 'UTF-8', $file );

        my $tmpdir = tempdir();
        chdir $tmpdir;

        open my $fh, '>', $file_utf8;
        print {$fh} "hello world\n";
        close $fh;

        my @dirs;

        my $chdir = sub { App::DCMP::_chdir( File::Spec->catdir($tmpdir), @_ ) };

        like( exception { App::DCMP::_compare_file_record_fs( $chdir, \@dirs, $file, undef, undef ) }, encode( 'UTF-8', "/ ^ \Qbinmode failed for $file: \E /xsm" ), '_collect_file_info_dcmp_file throws an exception if binmode failes' );
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
