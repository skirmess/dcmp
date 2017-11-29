#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd 'cwd';
use Encode;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    package App::DCMP;
    use subs 'readlink';

    package main;

    *App::DCMP::readlink = sub { return };

  SKIP: {
        {
            no autodie;
            skip 'The symlink function is unimplemented' if !eval { symlink q{}, q{}; 1 };
        }

        my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

        if ( $^O ne 'MSWin32' ) {
            push @suffixes, "a\nb";
        }

        for my $suffix (@suffixes) {
            note(q{----------------------------------------------------------});
            note( encode( 'UTF-8', "suffix: $suffix" ) );

            for my $dir_suffix (@suffixes) {
                note(q{----------------------------------------------------------});
                note( encode( 'UTF-8', "dir suffix: $dir_suffix" ) );

                my $dir = "dir1${dir_suffix}";
                my $dir_utf8 = encode( 'UTF-8', $dir );

                my $tmpdir = tempdir();
                chdir $tmpdir;

                if ( $dir ne q{} ) {
                    mkdir $dir_utf8;
                    chdir $dir_utf8;
                }

                $tmpdir = decode( 'UTF-8', cwd() );

                my $file      = "file${suffix}.txt";
                my $file_utf8 = encode( 'UTF-8', $file );
                my $link      = "link${suffix}.txt";
                my $link_utf8 = encode( 'UTF-8', $link );

                symlink $file_utf8, $link_utf8;

                like( exception { App::DCMP::_collect_file_info($link) }, encode( 'UTF-8', "/ ^ \Qreadlink failed for $link in $tmpdir: \E /xsm" ), '_collect_file_info throws an exception if readlink failes' );
            }
        }
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
