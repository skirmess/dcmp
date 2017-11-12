#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::MockModule;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Encode;
use File::Spec;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, "a\nb";
    }

    for my $dir_l_suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "left dir suffix: $dir_l_suffix" ) );

        my $dir_l = "dirL${dir_l_suffix}";
        my $dir_l_utf8 = encode( 'UTF-8', $dir_l );

        for my $dir_r_suffix (@suffixes) {
            note(q{----------------------------------------------------------});
            note( encode( 'UTF-8', "right dir suffix: $dir_r_suffix" ) );

            my $dir_r = "dirR${dir_r_suffix}";
            my $dir_r_utf8 = encode( 'UTF-8', $dir_r );

            for my $file_suffix (@suffixes) {
                note(q{----------------------------------------------------------});
                note( encode( 'UTF-8', "file suffix: $file_suffix" ) );

                my $file        = "file${file_suffix}.txt";
                my $file_utf8   = encode( 'UTF-8', $file );
                my $file2       = "file2${file_suffix}.txt";
                my $file2_utf8  = encode( 'UTF-8', $file );
                my $file3l      = "file3l${file_suffix}.txt";
                my $file3l_utf8 = encode( 'UTF-8', $file );
                my $file3r      = "file3r${file_suffix}.txt";
                my $file3r_utf8 = encode( 'UTF-8', $file );

                my $tmpdir_l = tempdir();
                my $tmpdir_r = tempdir();

                my @dirs;

                my $chdir_l = sub { App::DCMP::_chdir( File::Spec->catdir( $tmpdir_l, $dir_l ), @_ ) };
                my $chdir_r = sub { App::DCMP::_chdir( File::Spec->catdir( $tmpdir_r, $dir_r ), @_ ) };

                like( exception { App::DCMP::_compare_file_fs_fs( $chdir_l, $chdir_r, \@dirs, $file, undef, undef ) }, encode( 'UTF-8', "/ ^ \QCannot chdir to $tmpdir_l\E /xsm" ), 'left _chdir throws an error if basedir does not exist' );

                mkdir encode( 'UTF-8', File::Spec->catdir( $tmpdir_l, $dir_l ) );
                open my $fh, '>', encode( 'UTF-8', File::Spec->catfile( $tmpdir_l, $dir_l, $file ) );
                close $fh;

                like( exception { App::DCMP::_compare_file_fs_fs( $chdir_l, $chdir_r, \@dirs, $file, undef, undef ) }, encode( 'UTF-8', "/ ^ \QCannot chdir to $tmpdir_r\E /xsm" ), 'right _chdir throws an error if basedir does not exist' );

                #
                $tmpdir_l = File::Spec->catdir( tempdir(), $dir_l );
                mkdir encode( 'UTF-8', $tmpdir_l );
                $tmpdir_r = File::Spec->catdir( tempdir(), $dir_r );
                mkdir encode( 'UTF-8', $tmpdir_r );

                $chdir_l = sub { App::DCMP::_chdir( $tmpdir_l, @_ ) };
                $chdir_r = sub { App::DCMP::_chdir( $tmpdir_r, @_ ) };

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $tmpdir_l, $file ) );
                print $fh "hello world\n";
                close $fh;

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $tmpdir_r, $file ) );
                print $fh "hello world\n";
                close $fh;

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $tmpdir_l, $file2 ) );
                print $fh "hello world L\n";
                close $fh;

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $tmpdir_r, $file2 ) );
                print $fh "hello world R\n";
                close $fh;

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $tmpdir_l, $file3l ) );
                print $fh "hello world L\n";
                close $fh;

                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $tmpdir_r, $file3r ) );
                print $fh "hello world R\n";
                close $fh;

                like( exception { App::DCMP::_compare_file_fs_fs( $chdir_l, $chdir_r, \@dirs, $file3l, undef, undef ) }, encode( 'UTF-8', "/ ^ \QCannot read file $file3l in $tmpdir_r: \E /xsm" ), '_compare_file_fs_fs throws an error if the left file cannot be read' );
                like( exception { App::DCMP::_compare_file_fs_fs( $chdir_l, $chdir_r, \@dirs, $file3r, undef, undef ) }, encode( 'UTF-8', "/ ^ \QCannot read file $file3r in $tmpdir_l: \E /xsm" ), '_compare_file_fs_fs throws an error if the right file cannot be read' );

                is( App::DCMP::_compare_file_fs_fs( $chdir_l, $chdir_r, \@dirs, $file,  undef, undef ), 1,     'Identical file compare as identical' );
                is( App::DCMP::_compare_file_fs_fs( $chdir_l, $chdir_r, \@dirs, $file2, undef, undef ), undef, 'Not identical file compare as not identical' );

                #
                my $compare = Test::MockModule->new( 'App::DCMP', no_auto => 1 );
                $compare->mock( 'compare', sub { return -1; } );

                like( exception { App::DCMP::_compare_file_fs_fs( $chdir_l, $chdir_r, \@dirs, $file2, undef, undef ) }, encode( 'UTF-8', "/ ^ \QUnable to compare file $file2\E /xsm" ), '_compare_file_fs_fs throws an error if compare() returns a failure' );

            }
        }
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
