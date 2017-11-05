#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;
use Test::Fatal;

use Cwd qw(cwd);
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
        note( encode( 'UTF-8', "suffix: $suffix" ) );

        my $dir = encode( 'UTF-8', "dir${suffix}" );

        #
        note('basedir, no dirs');
        my $tmpdir = tempdir();
        chdir $tmpdir;
        mkdir $dir;
        chdir $dir;

        $tmpdir = decode( 'UTF-8', cwd() );
        chdir $basedir;

        note( encode( 'UTF-8', "\$tmpdir = $tmpdir" ) );

        is( App::DCMP::_chdir( $tmpdir, undef ), undef, '_chdir($tmpdir, undef) returns undef' );
        is( decode( 'UTF-8', cwd() ), $tmpdir, '... and the cwd is now $tmpdir' );

        #
      SKIP: {
            skip 'chmod 0 does not prevent us from entering a directory on Windows' if $^O eq 'MSWin32';

            #
            note('basedir without permissions, no dirs');
            chdir $basedir;
            chmod 0, encode( 'UTF-8', $tmpdir );

            like( exception { App::DCMP::_chdir( $tmpdir, undef ) }, encode( 'UTF-8', "/ ^ \QCannot chdir to $tmpdir: \E /xsm" ), '_chdir($tmpdir, undef) throws am error' );
            is( decode( 'UTF-8', cwd() ), $basedir, '... and the cwd is not changed' );
        }

        my @DIRS = (
            [ 'a' .. 'z' ],
            [
                "\N{U+20A0}",
                "\N{U+20A1}",
                "\N{U+20A2}",
                "\N{U+20A3}",
                "\N{U+20A4}",
                "\N{U+20A5}",
                "\N{U+20A6}",
                "\N{U+20A7}",
                "\N{U+20A8}",
                "\N{U+20A9}",
            ],
            [
                'A',
                "\N{U+20AA}",
                'B',
                "\N{U+20AB}",
                'C',
                "\N{U+20AC}",
                'D',
                "\N{U+20AD}",
                'E',
                "\N{U+20AE}",
            ],
            [
                "\N{U+20AA}",
                'B',
                "\N{U+20AB}",
                'C',
                "\N{U+20AC}",
                'D',
                "\N{U+20AD}",
                'E',
                "\N{U+20AE}",
                'F',
            ],
        );
        for my $dirs_ref (@DIRS) {

            #
            note( 'basedir, ' . scalar @{$dirs_ref} . ' dirs' );
            $tmpdir = tempdir();
            chdir $tmpdir;
            mkdir $dir;
            chdir $dir;

            $tmpdir = decode( 'UTF-8', cwd() );
            note( encode( 'UTF-8', "\$tmpdir = $tmpdir" ) );

            for my $d ( @{$dirs_ref} ) {
                my $d_utf8 = encode( 'UTF-8', $d );
                mkdir $d_utf8;
                chdir $d_utf8;
            }

            my $expected_dir = decode( 'UTF-8', cwd() );
            note( encode( 'UTF-8', "\$expected_dir = $expected_dir" ) );
            chdir $basedir;

            is( App::DCMP::_chdir( $tmpdir, $dirs_ref ), undef, '_chdir($tmpdir, $dirs_ref) returns undef' );
            is( decode( 'UTF-8', cwd() ), $expected_dir, '... and the cwd is correct' );

            #
          SKIP: {
                skip 'chmod 0 does not prevent us from entering a directory on Windows' if $^O eq 'MSWin32';
                #
                note( 'basedir, ' . scalar @{$dirs_ref} . ' dirs, one without permissions' );
                chdir $basedir;
                chmod 0, encode( 'UTF-8', File::Spec->catdir( $tmpdir, @{$dirs_ref}[ 0 .. 6 ] ) );

                my $last_good_dir = File::Spec->catdir( $tmpdir, @{$dirs_ref}[ 0 .. 5 ] );
                like( exception { App::DCMP::_chdir( $tmpdir, $dirs_ref ) }, encode( 'UTF-8', "/ ^ \QCannot chdir to ${$dirs_ref}[6] in $last_good_dir: \E /xsm" ), '_chdir($tmpdir, $dirs_ref) throws an error' );
                is( decode( 'UTF-8', cwd() ), $last_good_dir, '... and the cwd is changed up to where the error happend' );
            }
        }
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
