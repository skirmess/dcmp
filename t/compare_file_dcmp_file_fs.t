#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd 'cwd';
use Digest::MD5;
use Encode;
use File::Spec;

use lib qw(.);

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Suffixes;
use Local::Normalize_Filename;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        my $dir  = Local::Normalize_Filename::normalize_filename("dir${suffix_bin}");
        my $file = Local::Normalize_Filename::normalize_filename("file${suffix_bin}.txt");

        my $tmpdir = tempdir();

        my @dirs;

        my $chdir = sub { App::DCMP::_chdir( File::Spec->catdir( $tmpdir, $dir ), @_ ) };

        like( exception { App::DCMP::_compare_file_dcmp_file_fs( $chdir, \@dirs, $file, undef, undef ) }, "/ ^ \QCannot chdir to $tmpdir\E /xsm", '_chdir throws an error if basedir does not exist' );

        my $basedir = cwd();

        # cwd returns Unix dir separator on Windows but tempdir returns
        # Windows path separator on Windows. The error message in dcmp is
        # generated with cwd.

        my $_tmpdir = File::Spec->catdir( $tmpdir, $dir );
        mkdir $_tmpdir;
        chdir $_tmpdir;
        $_tmpdir = cwd();

        chdir $basedir;

        like( exception { App::DCMP::_compare_file_dcmp_file_fs( $chdir, \@dirs, $file, undef, undef ) }, "/ ^ \QCannot read file $file in $_tmpdir\E /xsm", '_compare_file_dcmp_file_fs throws an error if the file cannot be read' );

        open my $fh, '>', File::Spec->catfile( $tmpdir, $dir, $file );
        print {$fh} 'hello world';
        close $fh;

        my $md5 = Digest::MD5->new();
        $md5->add('hello world');
        my $md5_sum = $md5->hexdigest();

        is( App::DCMP::_compare_file_dcmp_file_fs( $chdir, \@dirs, $file, lc $md5_sum,     undef ), 1,     '_compare_file_dcmp_file_fs returns 1 if the file matches the lowercase md5 sum' );
        is( App::DCMP::_compare_file_dcmp_file_fs( $chdir, \@dirs, $file, uc $md5_sum,     undef ), 1,     '_compare_file_dcmp_file_fs returns 1 if the file matches the uppercase md5 sum' );
        is( App::DCMP::_compare_file_dcmp_file_fs( $chdir, \@dirs, $file, 'not a md5 sum', undef ), undef, '_compare_file_dcmp_file_fs returns undef if the file does not match the md5 sum' );

    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl