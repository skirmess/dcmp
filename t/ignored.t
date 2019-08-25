#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use Encode;
use File::Spec;

use lib qw(.);

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Suffixes;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        my $file        = "file${suffix_bin}.txt";
        my $ignore_file = "ignore${suffix_bin}.txt";

        # ----------------------------------------------------------
        note('no ignore paths, no ignore files, no dirs');
        {
            my @ignore_files;
            my @ignore_paths;
            my @dirs;

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), undef, '... which returns undef for another not ignored file' );
        }

        # ----------------------------------------------------------
        note('no ignore paths, one ignore file, no dirs');
        {
            my @ignore_files = ($ignore_file);
            my @ignore_paths;
            my @dirs;

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), 1,     '... which returns 1 for an ignored file' );
        }

        # ----------------------------------------------------------
        note('no ignore paths, five ignore file, no dirs');
        {
            my @ignore_files = ( 'a', 'b', $ignore_file, 'c', 'd' );
            my @ignore_paths;
            my @dirs;

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), 1,     '... which returns 1 for an ignored file' );
        }

        # ----------------------------------------------------------
        note('changing ignore file after ignore sub is created');
        {
            my @ignore_files;
            my @ignore_paths;
            my @dirs;

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            push @ignore_files, $ignore_file;

            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), undef, '... which returns undef for another not ignored file (changed @ignore_files is ignored)' );
        }

        my $dir1        = "dir1${suffix_bin}";
        my $dir2        = "dir2${suffix_bin}";
        my $ignore_path = File::Spec->catfile( $dir1, $ignore_file );

        # ----------------------------------------------------------
        note('one ignore paths, no ignore files, no dirs');
        {
            my @ignore_files;
            my @ignore_paths = ($ignore_path);
            my @dirs;

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), undef, '... which returns undef for another not ignored file' );
        }

        # ----------------------------------------------------------
        note('one ignore paths, no ignore files, one dir');
        {
            my @ignore_files;
            my @ignore_paths = ($ignore_path);
            my @dirs         = ($dir2);

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), undef, '... which returns undef for another not ignored file' );
        }

        # ----------------------------------------------------------
        note('one ignore paths, no ignore files, one dir');
        {
            my @ignore_files;
            my @ignore_paths = ($ignore_path);
            my @dirs         = ($dir1);

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), 1,     '... which returns 1 for an ignored file' );
        }

        # ----------------------------------------------------------
        note('one ignore paths, no ignore files, one dir');
        {
            my @ignore_files;
            my @ignore_paths = ($dir1);
            my @dirs         = ($dir2);

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), undef, '... which returns undef for another not ignored file' );
        }

        # ----------------------------------------------------------
        note('one ignore paths, no ignore files, one dir');
        {
            my @ignore_files;
            my @ignore_paths = ($dir1);
            my @dirs         = ($dir1);

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            is( $ignore->( \@dirs, $file ),        1, '... which returns 1 for an ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), 1, '... which returns 1 for another ignored file' );

            @dirs = ($dir2);
            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file (changed @dirs is used)' );
            is( $ignore->( \@dirs, $ignore_file ), undef, '... which returns undef for another not ignored file (changed @dirs is used)' );

            @ignore_paths = ($dir2);
            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file (changed @ignore_path is ignored)' );
            is( $ignore->( \@dirs, $ignore_file ), undef, '... which returns undef for another not ignored file (changed @ignore_path is ignored)' );
        }

        # ----------------------------------------------------------
        note('five ignore paths, no ignore files, one dir');
        {
            my @ignore_files;
            my @ignore_paths = ( 'a', 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', $ignore_path, 'c', 'e' );
            my @dirs         = ($dir1);

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), 1,     '... which returns 1 for an ignored file' );
        }

        my $dir3 = "dir3${suffix_bin}";
        my $dir4 = "dir4${suffix_bin}";
        $ignore_path = File::Spec->catfile( $dir1, $dir2, $dir3, $dir4, $ignore_file );

        # ----------------------------------------------------------
        note('one ignore paths, no ignore files, four dir');
        {
            my @ignore_files;
            my @ignore_paths = ($ignore_path);
            my @dirs         = ( $dir1, $dir2, $dir3 );

            my $ignore = App::DCMP::_ignored( \@ignore_paths, \@ignore_files );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), undef, '... which returns undef for another not ignored file' );

            push @dirs, $dir4;
            is( $ignore->( \@dirs, $file ),        undef, '... which returns undef for a not ignored file' );
            is( $ignore->( \@dirs, $ignore_file ), 1,     '... which returns 1 for an ignored file' );
        }
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
