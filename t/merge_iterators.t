#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd qw(cwd);
use Encode;
use File::Spec;

use lib qw(.);

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Normalize_Filename;
use Local::Suffixes;
use Local::Test::Util;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {

        my $dir_1_suffix_iterator = Local::Suffixes::suffix_iterator();

        while ( my ( $dir_1_suffix_text, $dir_1_suffix_bin ) = $dir_1_suffix_iterator->() ) {

            my $dir_2_suffix_iterator = Local::Suffixes::suffix_iterator();

            while ( my ( $dir_2_suffix_text, $dir_2_suffix_bin ) = $dir_2_suffix_iterator->() ) {

                _test_merge( $suffix_text, $suffix_bin, $dir_1_suffix_text, $dir_1_suffix_bin, $dir_2_suffix_text, $dir_2_suffix_bin );
            }
        }
    }

    #
    done_testing();

    exit 0;
}

sub _test_merge {
    my ( $suffix_text, $suffix_bin, $dir_1_suffix_text, $dir_1_suffix_bin, $dir_2_suffix_text, $dir_2_suffix_bin ) = @_;

    my $test = Local::Test::Util->new;

    note(q{----------------------------------------------------------});
    note( encode( 'UTF-8', "file suffix: $suffix_text" ) );
    note( encode( 'UTF-8', "dir 1 suffix: $dir_1_suffix_text" ) );
    note( encode( 'UTF-8', "dir 2 suffix: $dir_2_suffix_text" ) );

    my $basedir = cwd();

    my $file_a = "a{$suffix_bin}.txt";
    my $file_b = "b{$suffix_bin}.txt";
    my $file_c = "c{$suffix_bin}.txt";
    my $file_d = "d{$suffix_bin}.txt";
    my $file_e = "e{$suffix_bin}.txt";

    my $tmpdir_1 = File::Spec->catdir( tempdir(), "base${dir_1_suffix_bin}" );
    $test->mkdir($tmpdir_1);

    my $tmpdir_2 = File::Spec->catdir( tempdir(), "base${dir_2_suffix_bin}" );
    $test->mkdir($tmpdir_2);

    $test->chdir($tmpdir_1);

    $test->touch($file_a);
    $test->touch($file_b);
    $test->touch($file_d);

    $test->chdir($tmpdir_2);

    $test->touch($file_a);
    $test->touch($file_c);

    for my $pass ( 0 .. 1 ) {

        if ( $pass == 1 ) {
            $test->touch($file_e);
        }

        $test->chdir($basedir);

        my $chdir_1 = sub { App::DCMP::_chdir( $tmpdir_1, @_ ); };
        my $chdir_2 = sub { App::DCMP::_chdir( $tmpdir_2, @_ ); };

        my $collect_file_info = sub { App::DCMP::_collect_file_info(@_); };

        my @dirs;

        my $it_1 = App::DCMP::_iterator_dir_fs( $chdir_1, $collect_file_info, sub { }, \@dirs );
        my $it_2 = App::DCMP::_iterator_dir_fs( $chdir_2, $collect_file_info, sub { }, \@dirs );

        my $it = App::DCMP::_merge_iterators( $it_1, $it_2 );
        is( ref $it, ref sub { }, '_merge_iterators() returns a sub' );

        #
        note( encode( 'UTF-8', "$file_a / $file_a" ) );
        my $merged_file_info = $it->();
        is( ref $merged_file_info, ref [], 'merged file info is an array ref' );
        is( scalar @{$merged_file_info}, 2, '... consisting of two values' );
        is( ref ${$merged_file_info}[0], ref [], '... first value is an array ref' );
        is( ref ${$merged_file_info}[1], ref [], '... second value is an array ref' );

        my $file_info = ${$merged_file_info}[0];
        is( scalar @{$file_info}, 3, '... first consists of three values' );
        is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_a), '... the file name' );
        like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
        is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
        is( ${$file_info}[2], 0, '... the file size' );

        $file_info = ${$merged_file_info}[1];
        is( scalar @{$file_info}, 3, '... second consists of three values' );
        is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_a), '... the file name' );
        like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
        is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
        is( ${$file_info}[2], 0, '... the file size' );

        #
        note( encode( 'UTF-8', "undef / $file_b" ) );
        $merged_file_info = $it->();
        is( ref $merged_file_info, ref [], 'merged file info is an array ref' );
        is( scalar @{$merged_file_info}, 2, '... consisting of two values' );
        is( ref ${$merged_file_info}[0], ref [], '... first value is an array ref' );
        is( ${$merged_file_info}[1], undef, '... second value is undef' );

        $file_info = ${$merged_file_info}[0];
        is( ref $file_info, ref [], 'file info is an array ref' );
        is( scalar @{$file_info}, 3, '... consisting of three values' );
        is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_b), '... the file name' );
        like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
        is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
        is( ${$file_info}[2], 0, '... the file size' );

        #
        note( encode( 'UTF-8', "$file_c / undef" ) );
        $merged_file_info = $it->();

        is( ref $merged_file_info, ref [], 'merged file info is an array ref' );
        is( scalar @{$merged_file_info}, 2,     '... consisting of two values' );
        is( ${$merged_file_info}[0],     undef, '... first value is undef' );
        is( ref ${$merged_file_info}[1], ref [], '... second value is an array ref' );

        $file_info = ${$merged_file_info}[1];
        is( ref $file_info, ref [], 'file info is an array ref' );
        is( scalar @{$file_info}, 3, '... consisting of three values' );
        is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_c), '... the file name' );
        like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
        is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
        is( ${$file_info}[2], 0, '... the file size' );

        #
        note( encode( 'UTF-8', "undef / $file_d" ) );
        $merged_file_info = $it->();
        is( ref $merged_file_info, ref [], 'merged file info is an array ref' );
        is( scalar @{$merged_file_info}, 2, '... consisting of two values' );
        is( ref ${$merged_file_info}[0], ref [], '... first value is an array ref' );
        is( ${$merged_file_info}[1], undef, '... second value is undef' );

        $file_info = ${$merged_file_info}[0];
        is( ref $file_info, ref [], 'file info is an array ref' );
        is( scalar @{$file_info}, 3, '... consisting of three values' );
        is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_d), '... the file name' );
        like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
        is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
        is( ${$file_info}[2], 0, '... the file size' );

        if ( $pass == 1 ) {
            #
            note( encode( 'UTF-8', "$file_e / undef" ) );
            $merged_file_info = $it->();

            is( ref $merged_file_info, ref [], 'merged file info is an array ref' );
            is( scalar @{$merged_file_info}, 2,     '... consisting of two values' );
            is( ${$merged_file_info}[0],     undef, '... first value is undef' );
            is( ref ${$merged_file_info}[1], ref [], '... second value is an array ref' );

            $file_info = ${$merged_file_info}[1];
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 3, '... consisting of three values' );
            is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_e), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
            is( ${$file_info}[2], 0, '... the file size' );
        }

        #
        note('undef');
        is( $it->(), undef, 'merged file info is undef - iterator is exhausted.' );
    }

    #
    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
