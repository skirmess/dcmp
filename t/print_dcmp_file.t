#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use Encode;
use File::Spec;

use lib qw(.);

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Normalize_Filename;
use Local::Suffixes;
use Local::Symlink;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $basedir = cwd();

    my $suffix_iterator = _suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        my $dir                    = Local::Normalize_Filename::normalize_filename("dir${suffix_bin}");
        my $dir_escaped            = App::DCMP::_escape_filename($dir);
        my $file                   = Local::Normalize_Filename::normalize_filename("file${suffix_bin}.txt");
        my $file_escaped           = App::DCMP::_escape_filename($file);
        my $file2                  = Local::Normalize_Filename::normalize_filename("file2${suffix_bin}.txt");
        my $file2_escaped          = App::DCMP::_escape_filename($file2);
        my $invalid_link           = Local::Normalize_Filename::normalize_filename("invalid_link${suffix_bin}.txt");
        my $invalid_link_escaped   = App::DCMP::_escape_filename($invalid_link);
        my $invalid_target         = Local::Normalize_Filename::normalize_filename("invalid_target${suffix_bin}.txt");
        my $invalid_target_escaped = App::DCMP::_escape_filename($invalid_target);
        my $valid_link             = Local::Normalize_Filename::normalize_filename("valid_link${suffix_bin}.txt");
        my $valid_link_escaped     = App::DCMP::_escape_filename($valid_link);

        my $tmpdir = tempdir();
        chdir $tmpdir;

        open my $fh, '>', $file;
        print {$fh} 'hello world';
        close $fh;
        my $file_size = -s $file;

        my $expected_output_lines = 5;
        if ( Local::Symlink::symlink_supported() ) {
            symlink $file,           $valid_link;
            symlink $invalid_target, $invalid_link;
            $expected_output_lines += 2;
        }

        mkdir $dir;

        open $fh, '>', File::Spec->catfile( $dir, $file2 );
        close $fh;

        chdir $basedir;

        my $chdir             = sub { return App::DCMP::_chdir( $tmpdir, @_ ); };
        my $collect_file_info = sub { return App::DCMP::_collect_file_info_dcmp_file(@_); };
        my $iterate_dir_fs    = sub { return App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, undef, @_ ); };

        my ( $stdout, $stderr, @result );

        ( $stdout, $stderr, @result ) = capture { App::DCMP::_print_dcmp_file($iterate_dir_fs); };
        is( @result, 0, '_print_dcmp_file returns nothing' );
        my @stdout = split /\n/xsm, $stdout;

        is( @stdout, $expected_output_lines, "... prints $expected_output_lines lines to stdout" );
        my $i = 0;
        is( $stdout[ $i++ ], "DIR $dir_escaped",                                               encode( 'UTF-8', "...DIR $dir_escaped" ) );
        is( $stdout[ $i++ ], "FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e",         encode( 'UTF-8', "... FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e" ) );
        is( $stdout[ $i++ ], '-DIR',                                                           '... -DIR' );
        is( $stdout[ $i++ ], "FILE $file_escaped $file_size 5eb63bbbe01eeed093cb22bb8f5acdc3", encode( 'UTF-8', "... FILE $file_escaped $file_size 5eb63bbbe01eeed093cb22bb8f5acdc3" ) );
        is( $stdout[ $i++ ], "LINK $invalid_link_escaped $invalid_target_escaped",             encode( 'UTF-8', "... LINK $invalid_link_escaped $invalid_target_escaped" ) );
        is( $stdout[ $i++ ], "LINK $valid_link_escaped $file_escaped",                         encode( 'UTF-8', "... LINK $valid_link_escaped $file_escaped" ) );
        is( $stdout[ $i++ ], '-DIR',                                                           '... -DIR' );

        is( $stderr, q{}, '... prints nothing to stderr' );

    }
    #
    done_testing();

    exit 0;
}

sub _suffix_iterator {
    my $suffix_iterator     = Local::Suffixes::suffix_iterator();
    my @additional_suffixes = (' hello world ');

    return sub {
        while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
            return $suffix_text, $suffix_bin;
        }

        while ( defined( my $suffix = shift @additional_suffixes ) ) {
            return $suffix, $suffix;
        }

        return;
    };
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
