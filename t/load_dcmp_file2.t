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

use FindBin qw($Bin);
use lib "$Bin/lib";

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

        my $dcmp_file     = File::Spec->catfile( tempdir(), "file${suffix_bin}.dcmp" );
        my $file2         = "file2${suffix_bin}.txt";
        my $file2_escaped = App::DCMP::_escape_filename($file2);

        open my $fh, '>', $dcmp_file;
        print {$fh} <<"RECORD_FILE";
dcmp v1
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, "/ ^ \QCannot read file $dcmp_file: \E /xsm", '_load_dcmp_file() throws an exception if close fails' );
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
