#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test2::Plugin::UTF8;
use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Encode;
use POSIX 'mkfifo';

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    for my $suffix ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" ) {
        note(q{----------------------------------------------------------});
        note("suffix: $suffix");

        my $dir            = encode( 'UTF-8', "dir${suffix}" );
        my $fifo           = encode( 'UTF-8', "fifo${suffix}" );
        my $file           = encode( 'UTF-8', "file${suffix}.txt" );
        my $invalid_file   = encode( 'UTF-8', "invalid_file${suffix}" );
        my $invalid_link   = encode( 'UTF-8', "invalid_link${suffix}.txt" );
        my $invalid_target = encode( 'UTF-8', "invalid_target${suffix}.txt" );
        my $valid_link     = encode( 'UTF-8', "valid_link${suffix}.txt" );

        my $tmpdir = tempdir();
        chdir $tmpdir;

        open my $fh, '>', $file;
        print {$fh} "hello world\n";
        close $fh;
        my $file_size = -s $file;

        mkdir $dir;

        # ----------------------------------------------------------
        note( decode( 'UTF-8', $invalid_file ) );

        like( exception { App::DCMP::_collect_file_info($invalid_file) }, "/ ^ \QCannot stat file $invalid_file in $tmpdir: \E /xsm", '_collect_file_info throws an exception if lstat failes' );

        # ----------------------------------------------------------
        note( decode( 'UTF-8', $dir ) );

        my $file_info = App::DCMP::_collect_file_info($dir);
        is( ref $file_info, ref [], '_collect_file_info() returns an array ref' );
        is( scalar @{$file_info}, 2,                                '... consisting of two values' );
        is( ${$file_info}[0],     $dir,                             '... the file name' );
        is( ${$file_info}[1],     App::DCMP::FILE_TYPE_DIRECTORY(), '... the type (directory)' );

        # ----------------------------------------------------------
        note( decode( 'UTF-8', $file ) );
        $file_info = App::DCMP::_collect_file_info($file);
        is( ref $file_info, ref [], '_collect_file_info() returns an array ref' );
        is( scalar @{$file_info}, 3,                              '... consisting of three values' );
        is( ${$file_info}[0],     $file,                          '... the file name' );
        is( ${$file_info}[1],     App::DCMP::FILE_TYPE_REGULAR(), '... the type (regular)' );
        is( ${$file_info}[2],     $file_size,                     '... the file size' );

      SKIP: {
            {
                no autodie;
                skip 'The symlink function is unimplemented' if !eval { symlink q{}, q{}; 1 };
            }

            symlink $file,           $valid_link;
            symlink $invalid_target, $invalid_link;

            # ----------------------------------------------------------
            note( decode( 'UTF-8', $valid_link ) );
            $file_info = App::DCMP::_collect_file_info($valid_link);
            is( ref $file_info, ref [], '_collect_file_info() returns an array ref' );
            is( scalar @{$file_info}, 3,                              '... consisting of three values' );
            is( ${$file_info}[0],     $valid_link,                    '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... the type (symlink)' );
            is( ${$file_info}[2],     $file,                          '... the links valid target' );

            # ----------------------------------------------------------
            note( decode( 'UTF-8', $invalid_link ) );
            $file_info = App::DCMP::_collect_file_info($invalid_link);
            is( ref $file_info, ref [], '_collect_file_info() returns an array ref' );
            is( scalar @{$file_info}, 3,                              '... consisting of three values' );
            is( ${$file_info}[0],     $invalid_link,                  '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... the type (symlink)' );
            is( ${$file_info}[2],     $invalid_target,                '... the links invalid target' );
        }

      SKIP: {
            {
                no autodie;
                skip 'The mkfifo function is unimplemented' if !eval { mkfifo q{}, q{}; 1 };
            }

            mkfifo $fifo, 0666;

            # ----------------------------------------------------------
            note( decode( 'UTF-8', $fifo ) );
            $file_info = App::DCMP::_collect_file_info($fifo);
            is( ref $file_info, ref [], '_collect_file_info() returns an array ref' );
            is( scalar @{$file_info}, 2,                            '... consisting of two values' );
            is( ${$file_info}[0],     $fifo,                        '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_OTHER(), '... the type (other)' );
        }

    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
