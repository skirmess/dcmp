#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Digest::MD5;
use Encode;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, "a\nb";
    }

    for my $suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix" ) );

        my $dir  = "dir${suffix}";
        my $file = "file${suffix}.txt";

        my $tmpdir = tempdir();

        my @dirs;

        my $chdir = sub { App::DCMP::_chdir( File::Spec->catdir( $tmpdir, $dir ), @_ ) };

        like( exception { App::DCMP::_compare_file_record_fs( $chdir, \@dirs, $file, undef, undef ) }, encode( 'UTF-8', "/ ^ \QCannot chdir to $tmpdir\E /xsm" ), '_chdir throws an error if basedir does not exist' );

        mkdir encode( 'UTF-8', File::Spec->catdir( $tmpdir, $dir ) );

        like( exception { App::DCMP::_compare_file_record_fs( $chdir, \@dirs, $file, undef, undef ) }, encode( 'UTF-8', "/ ^ \QCannot read file $file in $tmpdir\E /xsm" ), '_compare_file_record_fs throws an error if the file cannot be read' );

        open my $fh, '>', encode( 'UTF-8', File::Spec->catfile( $tmpdir, $dir, $file ) );
        print {$fh} 'hello world';
        close $fh;

        my $md5 = Digest::MD5->new();
        $md5->add('hello world');
        my $md5_sum = $md5->hexdigest();

        is( App::DCMP::_compare_file_record_fs( $chdir, \@dirs, $file, lc $md5_sum,     undef ), 1,     '_compare_file_record_fs returns 1 if the file matches the lowercase md5 sum' );
        is( App::DCMP::_compare_file_record_fs( $chdir, \@dirs, $file, uc $md5_sum,     undef ), 1,     '_compare_file_record_fs returns 1 if the file matches the uppercase md5 sum' );
        is( App::DCMP::_compare_file_record_fs( $chdir, \@dirs, $file, 'not a md5 sum', undef ), undef, '_compare_file_record_fs returns undef if the file does not match the md5 sum' );

    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
