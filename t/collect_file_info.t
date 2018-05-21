#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd 'cwd';
use Encode;
use POSIX 'mkfifo';

use lib qw(.);

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Fifo;
use Local::Suffixes;
use Local::Symlink;
use Local::Test::Util;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();
    my $test            = Local::Test::Util->new;

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        my $dir               = "dir${suffix_bin}";
        my $dir_text          = "dir${suffix_text}";
        my $fifo              = "fifo${suffix_bin}";
        my $fifo_text         = "fifo${suffix_text}";
        my $file              = "file${suffix_bin}.txt";
        my $file_text         = "file${suffix_text}.txt";
        my $invalid_file      = "invalid_file${suffix_bin}.txt";
        my $invalid_file_text = "invalid_file${suffix_text}.txt";
        my $invalid_link      = "invalid_link${suffix_bin}.txt";
        my $invalid_link_text = "invalid_link${suffix_text}.txt";
        my $invalid_target    = "invalid_target${suffix_bin}.txt";
        my $valid_link        = "valid_link${suffix_bin}.txt";
        my $valid_link_text   = "valid_link${suffix_text}.txt";

        my $dir_suffix_iterator = Local::Suffixes::suffix_iterator();
        while ( my ( $dir_suffix_text, $dir_suffix_bin ) = $dir_suffix_iterator->() ) {
            note(q{----------------------------------------------------------});
            note( encode( 'UTF-8', "dir suffix: $dir_suffix_text" ) );

            my $tmpdir = tempdir();
            $test->chdir($tmpdir);

            my $ws = "ws$dir_suffix_bin";

            $test->mkdir($ws);
            $test->chdir($ws);

            # cwd returns Unix dir separator on Windows but tempdir returns
            # Windows path separator on Windows. The error message in dcmp is
            # generated with cwd.
            $tmpdir = cwd();

            $test->touch( $file, "hello world\n" );
            my $file_size = -s $file;

            $test->mkdir($dir);

            # ----------------------------------------------------------
            note( encode( 'UTF-8', $invalid_file_text ) );

            like( exception { App::DCMP::_collect_file_info($invalid_file) }, "/ ^ \QCannot stat file $invalid_file in $tmpdir: \E /xsm", '_collect_file_info throws an exception if stat failes' );

            # ----------------------------------------------------------
            note( encode( 'UTF-8', $dir_text ) );

            my $file_info = App::DCMP::_collect_file_info($dir);
            is( ref $file_info, ref [], '_collect_file_info() returns an array ref' );
            is( scalar @{$file_info}, 2,                                '... consisting of two values' );
            is( ${$file_info}[0],     $dir,                             '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_DIRECTORY(), '... the type (directory)' );

            # ----------------------------------------------------------
            note( encode( 'UTF-8', $file_text ) );
            $file_info = App::DCMP::_collect_file_info($file);
            is( ref $file_info, ref [], '_collect_file_info() returns an array ref' );
            is( scalar @{$file_info}, 3,                              '... consisting of three values' );
            is( ${$file_info}[0],     $file,                          '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_REGULAR(), '... the type (regular)' );
            is( ${$file_info}[2],     $file_size,                     '... the file size' );

          SKIP: {
                skip 'The symlink function is unimplemented', 1 if !Local::Symlink::symlink_supported();

                $test->symlink( $file,           $valid_link );
                $test->symlink( $invalid_target, $invalid_link );

                # ----------------------------------------------------------
                note( encode( 'UTF-8', $valid_link_text ) );
                $file_info = App::DCMP::_collect_file_info($valid_link);
                is( ref $file_info, ref [], '_collect_file_info() returns an array ref' );
                is( scalar @{$file_info}, 3,                              '... consisting of three values' );
                is( ${$file_info}[0],     $valid_link,                    '... the file name' );
                is( ${$file_info}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... the type (symlink)' );
                is( ${$file_info}[2],     $file,                          '... the links valid target' );

                # ----------------------------------------------------------
                note( encode( 'UTF-8', $invalid_link_text ) );
                $file_info = App::DCMP::_collect_file_info($invalid_link);
                is( ref $file_info, ref [], '_collect_file_info() returns an array ref' );
                is( scalar @{$file_info}, 3,                              '... consisting of three values' );
                is( ${$file_info}[0],     $invalid_link,                  '... the file name' );
                is( ${$file_info}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... the type (symlink)' );
                is( ${$file_info}[2],     $invalid_target,                '... the links invalid target' );
            }

          SKIP: {
                skip 'The mkfifo function is unimplemented', 1 if !Local::Fifo::fifo_supported();

                mkfifo $fifo, 0666;

                # ----------------------------------------------------------
                note( encode( 'UTF-8', $fifo_text ) );
                $file_info = App::DCMP::_collect_file_info($fifo);
                is( ref $file_info, ref [], '_collect_file_info() returns an array ref' );
                is( scalar @{$file_info}, 2,                            '... consisting of two values' );
                is( ${$file_info}[0],     $fifo,                        '... the file name' );
                is( ${$file_info}[1],     App::DCMP::FILE_TYPE_OTHER(), '... the type (other)' );
            }
        }
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
