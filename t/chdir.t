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

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Suffixes;

main();

my $fail_chdir_on;

sub _fail_chdir_if {
    my ($dir) = @_;

    if ( defined $fail_chdir_on && $fail_chdir_on eq $dir ) {
        note("simulating error - refusing to chdir to '$dir'");
        return 0;
    }

    return chdir $dir;
}

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    package App::DCMP;
    use subs 'chdir';

    package main;
    *App::DCMP::chdir = \&_fail_chdir_if;

    my $basedir = cwd();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix = $suffix_text" ) );

        my $dir = "dir$suffix_bin";

        #
        note('basedir, no dirs');
        my $tmpdir = tempdir();
        chdir $tmpdir;
        mkdir $dir;
        chdir $dir;

        $tmpdir = cwd();
        chdir $basedir;

        note( "\$tmpdir = $tmpdir" );

        is( App::DCMP::_chdir( $tmpdir, undef ), undef, '_chdir($tmpdir, undef) returns undef' );
        is( cwd(), $tmpdir, '... and the cwd is now $tmpdir' );

        #
        note('chdir to basedir fails, no dirs');

        chdir $basedir;


        $fail_chdir_on = $tmpdir;
        like( exception { App::DCMP::_chdir( $tmpdir, undef ) }, "/ ^ \QCannot chdir to $tmpdir: \E /xsm" , '_chdir($tmpdir, undef) throws am error' );
        is( cwd(), $basedir, '... and the cwd is not changed' );

        $fail_chdir_on = undef;

        my @dirs = (
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
        for my $dirs_ref_text (@dirs) {
            my $dirs_ref = [ map { encode('UTF-8', $_) } @{$dirs_ref_text} ];

            #
            note( 'basedir, ' . scalar @{$dirs_ref} . ' dirs' );
            $tmpdir = tempdir();
            chdir $tmpdir;
            mkdir $dir;
            chdir $dir;

            $tmpdir = cwd();
            note( "\$tmpdir = $tmpdir" );

            for my $d ( @{$dirs_ref} ) {
                mkdir $d;
                chdir $d;
            }

            my $expected_dir = cwd();
            note( "\$expected_dir = $expected_dir" );
            chdir $basedir;

            is( App::DCMP::_chdir( $tmpdir, $dirs_ref ), undef, '_chdir($tmpdir, $dirs_ref) returns undef' );
            is( cwd() , $expected_dir, '... and the cwd is correct' );

            #
            note( 'basedir, ' . scalar @{$dirs_ref} . ' dirs, one without permissions' );

            $fail_chdir_on = ${$dirs_ref}[6];

            my $last_good_dir = File::Spec->catdir( $tmpdir, @{$dirs_ref}[ 0 .. 5 ] );
            chdir $last_good_dir;
            $last_good_dir = cwd();
            chdir $basedir;


            like( exception { App::DCMP::_chdir( $tmpdir, $dirs_ref ) }, "/ ^ \QCannot chdir to ${$dirs_ref}[6] in $last_good_dir: \E /xsm" , '_chdir($tmpdir, $dirs_ref) throws an error' );
            is( cwd() , $last_good_dir, '... and the cwd is changed up to where the error happend' );

            $fail_chdir_on = undef;
        }
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
