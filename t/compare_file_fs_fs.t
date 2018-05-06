#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::MockModule;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd 'cwd';
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

                _test_compare_file_fs_fs( $suffix_text, $suffix_bin, $dir_1_suffix_text, $dir_1_suffix_bin, $dir_2_suffix_text, $dir_2_suffix_bin );
            }
        }
    }

    #
    done_testing();

    exit 0;
}

sub _test_compare_file_fs_fs {
    my ( $suffix_text, $suffix_bin, $dir_1_suffix_text, $dir_1_suffix_bin, $dir_2_suffix_text, $dir_2_suffix_bin ) = @_;

    my $test = Local::Test::Util->new;

    note(q{----------------------------------------------------------});
    note( encode( 'UTF-8', "suffix: $suffix_text" ) );
    note( encode( 'UTF-8', "dir 1 suffix: $dir_1_suffix_text" ) );
    note( encode( 'UTF-8', "dir 2 suffix: $dir_2_suffix_text" ) );

    my $dir_1 = Local::Normalize_Filename::normalize_filename("dir_1_${dir_1_suffix_bin}");
    my $dir_2 = Local::Normalize_Filename::normalize_filename("dir_2_${dir_2_suffix_bin}");

    my $file    = Local::Normalize_Filename::normalize_filename("file${suffix_bin}.txt");
    my $file2   = Local::Normalize_Filename::normalize_filename("file2${suffix_bin}.txt");
    my $file3_1 = Local::Normalize_Filename::normalize_filename("file3_1${suffix_bin}.txt");
    my $file3_2 = Local::Normalize_Filename::normalize_filename("file3_2${suffix_bin}.txt");

    my $tmpdir_1 = tempdir();
    my $tmpdir_2 = tempdir();

    my @dirs;

    my $chdir_1 = sub { App::DCMP::_chdir( File::Spec->catdir( $tmpdir_1, $dir_1 ), @_ ) };
    my $chdir_2 = sub { App::DCMP::_chdir( File::Spec->catdir( $tmpdir_2, $dir_2 ), @_ ) };

    my $compare_file = App::DCMP::_compare_file( $chdir_1, $chdir_2, \@dirs );
    is( ref $compare_file, ref sub { }, '_compare_file returns a function' );

    like( exception { $compare_file->($file) }, "/ ^ \QCannot chdir to $tmpdir_1\E /xsm", 'first _chdir throws an error if basedir does not exist' );

    $test->mkdir( File::Spec->catdir( $tmpdir_1, $dir_1 ) );
    $test->touch( File::Spec->catfile( $tmpdir_1, $dir_1, $file ) );

    like( exception { $compare_file->($file) }, "/ ^ \QCannot chdir to $tmpdir_2\E /xsm", 'second _chdir throws an error if basedir does not exist' );

    #
    my $basedir = cwd();

    # cwd returns Unix dir separator on Windows but tempdir returns
    # Windows path separator on Windows. The error message in dcmp is
    # generated with cwd.
    $tmpdir_1 = File::Spec->catdir( tempdir(), $dir_1 );
    $test->mkdir($tmpdir_1);
    $test->chdir($tmpdir_1);
    $tmpdir_1 = cwd();

    $tmpdir_2 = File::Spec->catdir( tempdir(), $dir_2 );
    $test->mkdir($tmpdir_2);
    $test->chdir($tmpdir_2);
    $tmpdir_2 = cwd();

    $test->chdir($basedir);

    $chdir_1 = sub { App::DCMP::_chdir( $tmpdir_1, @_ ) };
    $chdir_2 = sub { App::DCMP::_chdir( $tmpdir_2, @_ ) };

    $compare_file = App::DCMP::_compare_file( $chdir_1, $chdir_2, \@dirs );
    is( ref $compare_file, ref sub { }, '_compare_file returns a function' );

    $test->touch( File::Spec->catfile( $tmpdir_1, $file ),    "hello world\n" );
    $test->touch( File::Spec->catfile( $tmpdir_2, $file ),    "hello world\n" );
    $test->touch( File::Spec->catfile( $tmpdir_1, $file2 ),   "hello world 1\n" );
    $test->touch( File::Spec->catfile( $tmpdir_2, $file2 ),   "hello world 2\n" );
    $test->touch( File::Spec->catfile( $tmpdir_1, $file3_1 ), "hello world 1\n" );
    $test->touch( File::Spec->catfile( $tmpdir_2, $file3_2 ), "hello world 2\n" );

    like( exception { $compare_file->($file3_1) }, "/ ^ \QCannot read file $file3_1 in $tmpdir_2: \E /xsm", '_compare_file_fs_fs throws an error if the first file cannot be read' );
    like( exception { $compare_file->($file3_2) }, "/ ^ \QCannot read file $file3_2 in $tmpdir_1: \E /xsm", '_compare_file_fs_fs throws an error if the second file cannot be read' );

    is( $compare_file->($file),  1,     'Identical file compare as identical' );
    is( $compare_file->($file2), undef, 'Not identical file compare as not identical' );

    #
    my $compare = Test::MockModule->new( 'App::DCMP', no_auto => 1 );
    $compare->mock( 'compare', sub { return -1; } );

    like( exception { $compare_file->($file2) }, "/ ^ \QUnable to compare file $file2\E /xsm", '_compare_file_fs_fs throws an error if compare() returns a failure' );

    return;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
