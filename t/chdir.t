#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test2::Plugin::UTF8;
use Test::More 0.88;
use Test::TempDir::Tiny;
use Test::Fatal;

use Cwd qw(abs_path cwd);
use Encode;
use File::Spec;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $basedir = cwd();

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, "a\nb";
    }

    for my $suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note("suffix: $suffix");

        my $dir = encode( 'UTF-8', "dir${suffix}" );

        #
        note('basedir, no dirs');
        my $tmpdir = tempdir();
        chdir $tmpdir;
        if ( $dir ne q{} ) {
            mkdir $dir;
            chdir $dir;
        }

        $tmpdir = cwd();
        chdir $basedir;

        note( '$tmpdir = ' . decode( 'UTF-8', $tmpdir ) );

        is( App::DCMP::_chdir( $tmpdir, undef ), undef, '_chdir($tmpdir, undef) returns undef' );
        is( cwd(), $tmpdir, '... and the cwd is now $tmpdir' );

        #
      SKIP: {
            skip 'chmod 0 does not prevent us from entering a directory on Windows' if $^O eq 'MSWin32';

            #
            note('basedir without permissions, no dirs');
            chdir $basedir;
            chmod 0, $tmpdir;

            like( exception { App::DCMP::_chdir( $tmpdir, undef ) }, "/ ^ \QCannot chdir to $tmpdir: \E /xsm", '_chdir($tmpdir, undef) throws am error' );
            is( cwd(), $basedir, '... and the cwd is not changed' );
        }

        #
        note('basedir, 26 dirs');
        $tmpdir = tempdir();
        chdir $tmpdir;
        if ( $dir ne q{} ) {
            mkdir $dir;
            chdir $dir;
        }
        $tmpdir = cwd();
        note( '$tmpdir = ' . decode( 'UTF-8', $tmpdir ) );

        for my $d ( 'a' .. 'z' ) {
            mkdir $d;
            chdir $d;
        }

        my $expected_dir = cwd();
        note( '$expected_dir = ' . decode( 'UTF-8', $expected_dir ) );
        chdir $basedir;

        my @dirs = ( 'a' .. 'z' );

        is( App::DCMP::_chdir( $tmpdir, \@dirs ), undef, '_chdir($tmpdir, \@dirs) returns undef' );
        is( cwd(), $expected_dir, '... and the cwd is correct' );

        #
      SKIP: {
            skip 'chmod 0 does not prevent us from entering a directory on Windows' if $^O eq 'MSWin32';
            #
            note('basedir, 26 dirs, one without permissions');
            chdir $basedir;
            chmod 0, File::Spec->catdir( $tmpdir, 'a' .. 'f' );

            my $last_good_dir = File::Spec->catdir( $tmpdir, 'a' .. 'e' );
            like( exception { App::DCMP::_chdir( $tmpdir, \@dirs ) }, "/ ^ \QCannot chdir to f in $last_good_dir: \E /xsm", '_chdir($tmpdir, \@dirs) throws an error' );
            is( cwd(), $last_good_dir, '... and the cwd is changed up to where the error happend' );
        }
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
