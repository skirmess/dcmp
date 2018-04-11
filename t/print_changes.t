#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;

use Capture::Tiny qw(capture);
use Encode;
use File::Spec;

use lib qw(.);

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Declared;
use Local::Suffixes;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my %const = (
        'App::DCMP::FILE_ADDITIONAL'      => App::DCMP::FILE_ADDITIONAL(),
        'App::DCMP::FILE_MISSING'         => App::DCMP::FILE_MISSING(),
        'App::DCMP::FILE_TYPE_DIFFERS'    => App::DCMP::FILE_TYPE_DIFFERS(),
        'App::DCMP::FILE_TYPE_UNKNOWN'    => App::DCMP::FILE_TYPE_UNKNOWN(),
        'App::DCMP::FILE_CONTENT_DIFFERS' => App::DCMP::FILE_CONTENT_DIFFERS(),
        'App::DCMP::LINK_TARGET_DIFFERS'  => App::DCMP::LINK_TARGET_DIFFERS(),
    );

    for my $const ( keys %const ) {
        ok( Local::Declared::declared($const), "constant $const is defined" );
        like( $const{$const}, '/ ^ [0-9] + $ /xsm', '... is a number' );
      OTHER_CONST:
        for my $other_const ( keys %const ) {
            next OTHER_CONST if $const eq $other_const;

            isnt( $const{$const}, $const{$other_const}, "$const ($const{$const}) is not the same as $other_const ($const{$other_const})" );
        }
    }

    note('_print_changes');
    my $printer = App::DCMP::_print_changes();
    is( ref $printer, ref sub { }, '_print_changes() returns a sub' );

    my ( $stdout, $stderr, @result );
    my @dirs;
    my $expected_stdout;

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        my $dir_suffix_iterator = Local::Suffixes::suffix_iterator();

        while ( my ( $dir_suffix_text, $dir_suffix_bin ) = $dir_suffix_iterator->() ) {
            note(q{----------------------------------------------------------});
            note( encode( 'UTF-8', "dir suffix: $dir_suffix_text" ) );

            my $dir  = "dir1${dir_suffix_bin}";
            my $file = "file${suffix_bin}.txt";

            note('printer with empty path / FILE_ADDITIONAL');
            @dirs = ();
            ( $stdout, $stderr, @result ) = capture { $printer->( \@dirs, App::DCMP::FILE_ADDITIONAL(), $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = "+ $file\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

            note('printer with one path element / FILE_MISSING');
            @dirs = ($dir);
            ( $stdout, $stderr, @result ) = capture { $printer->( \@dirs, App::DCMP::FILE_MISSING(), $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = q{- } . File::Spec->catdir( $dir, $file ) . "\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

            note('printer with two path element / FILE_TYPE_DIFFERS');
            @dirs = ( $dir, 'dir2' );
            ( $stdout, $stderr, @result ) = capture { $printer->( \@dirs, App::DCMP::FILE_TYPE_DIFFERS(), $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = q{@ } . File::Spec->catdir( $dir, 'dir2', $file ) . "\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

            note('printer with two path element / FILE_TYPE_UNKNOWN');
            @dirs = ( $dir, 'dir2' );
            ( $stdout, $stderr, @result ) = capture { $printer->( \@dirs, App::DCMP::FILE_TYPE_UNKNOWN(), $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = q{? } . File::Spec->catdir( $dir, 'dir2', $file ) . "\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

            note('printer with two path element / FILE_CONTENT_DIFFERS');
            @dirs = ( $dir, 'dir2' );
            ( $stdout, $stderr, @result ) = capture { $printer->( \@dirs, App::DCMP::FILE_CONTENT_DIFFERS(), $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = q{M } . File::Spec->catdir( $dir, 'dir2', $file ) . "\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

            note('printer with two path element / LINK_TARGET_DIFFERS');
            @dirs = ( $dir, 'dir2' );
            ( $stdout, $stderr, @result ) = capture { $printer->( \@dirs, App::DCMP::LINK_TARGET_DIFFERS(), $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = q{L } . File::Spec->catdir( $dir, 'dir2', $file ) . "\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );
        }
    }

    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
