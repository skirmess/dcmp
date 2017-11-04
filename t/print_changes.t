#!perl

use 5.006;
use strict;
use warnings;

use Test2::Plugin::UTF8;
use Test::More 0.88;

use Capture::Tiny qw(capture);
use Encode;
use File::Spec;

use lib qw(.);

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
        ok( declared($const), "constant $const is defined" );
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

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, "a\nb";
    }

    for my $suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note("suffix: $suffix");

        for my $dir_suffix (@suffixes) {
            note(q{----------------------------------------------------------});
            note("dir suffix: $dir_suffix");

            my $dir  = encode( 'UTF-8', "dir1${dir_suffix}" );
            my $file = encode( 'UTF-8', "file${suffix}.txt" );

            note('printer with empty path / FILE_ADDITIONAL');
            @dirs = ();
            ( $stdout, $stderr, @result ) = capture { $printer->( App::DCMP::FILE_ADDITIONAL(), \@dirs, $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = "+ $file\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

            note('printer with one path element / FILE_MISSING');
            @dirs = ($dir);
            ( $stdout, $stderr, @result ) = capture { $printer->( App::DCMP::FILE_MISSING(), \@dirs, $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = q{- } . File::Spec->catdir( $dir, $file ) . "\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

            note('printer with two path element / FILE_TYPE_DIFFERS');
            @dirs = ( $dir, 'dir2' );
            ( $stdout, $stderr, @result ) = capture { $printer->( App::DCMP::FILE_TYPE_DIFFERS(), \@dirs, $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = q{@ } . File::Spec->catdir( $dir, 'dir2', $file ) . "\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

            note('printer with two path element / FILE_TYPE_UNKNOWN');
            @dirs = ( $dir, 'dir2' );
            ( $stdout, $stderr, @result ) = capture { $printer->( App::DCMP::FILE_TYPE_UNKNOWN(), \@dirs, $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = q{? } . File::Spec->catdir( $dir, 'dir2', $file ) . "\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

            note('printer with two path element / FILE_CONTENT_DIFFERS');
            @dirs = ( $dir, 'dir2' );
            ( $stdout, $stderr, @result ) = capture { $printer->( App::DCMP::FILE_CONTENT_DIFFERS(), \@dirs, $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = q{M } . File::Spec->catdir( $dir, 'dir2', $file ) . "\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

            note('printer with two path element / LINK_TARGET_DIFFERS');
            @dirs = ( $dir, 'dir2' );
            ( $stdout, $stderr, @result ) = capture { $printer->( App::DCMP::LINK_TARGET_DIFFERS(), \@dirs, $file ); };
            is( scalar @result, 0, '... which returns nothing' );
            $expected_stdout = q{L } . File::Spec->catdir( $dir, 'dir2', $file ) . "\n";
            is( $stdout, $expected_stdout, '... prints the correct message to stdout' );
            is( $stderr, q{}, '... prints nothing to stderr' );

        }
    }

    done_testing();

    exit 0;
}

# copied from 'perldoc constant'
sub declared ($) {
    use constant 1.01;    # don't omit this!
    my $name = shift;
    $name =~ s/^::/main::/xsm;
    my $pkg = caller;
    my $full_name = $name =~ /::/xsm ? $name : "${pkg}::$name";
    return $constant::declared{$full_name};
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
