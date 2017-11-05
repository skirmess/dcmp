#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd qw(cwd);
use Digest::MD5;
use Encode;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, "a\nb";
    }

    for my $suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix" ) );

        my $dir                 = "dir${suffix}";
        my $dir_utf8            = encode( 'UTF-8', $dir );
        my $file                = "file${suffix}.txt";
        my $file_utf8           = encode( 'UTF-8', $file );
        my $file2               = "file2${suffix}.txt";
        my $file2_utf8          = encode( 'UTF-8', $file2 );
        my $invalid_file        = "invalid_file${suffix}.txt";
        my $invalid_file_utf8   = encode( 'UTF-8', $invalid_file );
        my $invalid_link        = "invalid_link${suffix}.txt";
        my $invalid_link_utf8   = encode( 'UTF-8', $invalid_link );
        my $invalid_target      = "invalid_target${suffix}.txt";
        my $invalid_target_utf8 = encode( 'UTF-8', $invalid_target );
        my $valid_link          = "valid_link${suffix}.txt";
        my $valid_link_utf8     = encode( 'UTF-8', $valid_link );

        for my $dir_suffix (@suffixes) {
            note(q{----------------------------------------------------------});
            note( encode( 'UTF-8', "dir suffix: $dir_suffix" ) );

            # ----------------------------------------------------------
            my $tmpdir = tempdir();
            chdir $tmpdir;

            if ( $dir_suffix ne q{} ) {
                my $ws = "ws$dir_suffix";
                my $ws_utf8 = encode( 'UTF-8', $ws );

                mkdir $ws_utf8;
                chdir $ws_utf8;
            }

            # cwd returns Unix dir separator on Windows but tempdir returns
            # Windows path separator on Windows. The error message in dcmp is
            # generated with cwd.
            $tmpdir = decode( 'UTF8', cwd() );

            # ----------------------------------------------------------
            open my $fh, '>', $file_utf8;
            print {$fh} 'hello world';
            close $fh;
            my $file_size = -s $file_utf8;
            my $md5       = Digest::MD5->new();
            $md5->add('hello world');
            my $md5_sum = lc $md5->hexdigest();

            # ----------------------------------------------------------
            open $fh, '>:encoding(UTF-8)', $file2_utf8;
            print {$fh} "hello world\t\x{20ac}\t\x{00C0}\t\x{0041}\x{0300}";
            close $fh;
            my $file_utf8_size = -s $file2_utf8;
            $md5 = Digest::MD5->new();
            $md5->add( encode( 'UTF-8', "hello world\t\x{20ac}\t\x{00C0}\t\x{0041}\x{0300}" ) );
            my $md5_utf8_sum = lc $md5->hexdigest();

            # ----------------------------------------------------------
            mkdir $dir_utf8;

            # ----------------------------------------------------------
            like( exception { App::DCMP::_collect_file_info_report($invalid_file) }, encode( 'UTF-8', "/ ^ \QCannot stat file $invalid_file in $tmpdir: \E /xsm" ), '_collect_file_info_report throws an exception if stat failes' );

            # ----------------------------------------------------------
          SKIP: {
                skip 'chmod 0 does not prevent us from reading a file on Windows' if $^O eq 'MSWin32';

                open $fh, '>', $invalid_file_utf8;
                close $fh;
                chmod 0, $invalid_file_utf8;

                like( exception { App::DCMP::_collect_file_info_report($invalid_file) }, encode( 'UTF-8', "/ ^ \QCannot read file $invalid_file in $tmpdir: \E /xsm" ), '_collect_file_info_report throws an exception if it cannot read the file' );
            }

            # ----------------------------------------------------------
            note($dir_utf8);
            my $file_info = App::DCMP::_collect_file_info_report($dir);
            is( ref $file_info, ref [], '_collect_file_info_report() returns am array ref' );
            is( scalar @{$file_info}, 2,                                '... consisting of two values' );
            is( ${$file_info}[0],     $dir,                             '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_DIRECTORY(), '... the type (directory)' );

            # ----------------------------------------------------------
            note($file_utf8);
            $file_info = App::DCMP::_collect_file_info_report($file);
            is( ref $file_info, ref [], '_collect_file_info_report() returns am array ref' );
            is( scalar @{$file_info}, 4,                              '... consisting of four values' );
            is( ${$file_info}[0],     $file,                          '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_REGULAR(), '... the type (regular)' );
            is( ${$file_info}[2],     $file_size,                     '... the file size' );
            is( ${$file_info}[3],     $md5_sum,                       '... the md5 sum' );

            # ----------------------------------------------------------
            note($file2_utf8);
            $file_info = App::DCMP::_collect_file_info_report($file2);
            is( ref $file_info, ref [], '_collect_file_info_report() returns am array ref' );
            is( scalar @{$file_info}, 4,                              '... consisting of four values' );
            is( ${$file_info}[0],     $file2,                         '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_REGULAR(), '... the type (regular)' );
            is( ${$file_info}[2],     $file_utf8_size,                '... the file size' );
            is( ${$file_info}[3],     $md5_utf8_sum,                  '... the md5 sum' );

          SKIP: {
                {
                    no autodie;
                    skip 'The symlink function is unimplemented' if !eval { symlink q{}, q{}; 1 };
                }
                symlink $file_utf8,           $valid_link_utf8;
                symlink $invalid_target_utf8, $invalid_link_utf8;

                # ----------------------------------------------------------
                note($valid_link_utf8);
                $file_info = App::DCMP::_collect_file_info_report($valid_link);
                is( ref $file_info, ref [], '_collect_file_info_report() returns am array ref' );
                is( scalar @{$file_info}, 3,                              '... consisting of three values' );
                is( ${$file_info}[0],     $valid_link,                    '... the file name' );
                is( ${$file_info}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... the tyoe (symlink)' );
                is( ${$file_info}[2],     $file,                          '... the links valid target' );

                # ----------------------------------------------------------
                note($invalid_link_utf8);
                $file_info = App::DCMP::_collect_file_info_report($invalid_link);
                is( ref $file_info, ref [], '_collect_file_info_report() returns am array ref' );
                is( scalar @{$file_info}, 3,                              '... consisting of three values' );
                is( ${$file_info}[0],     $invalid_link,                  '... the file name' );
                is( ${$file_info}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... the type (symlink)' );
                is( ${$file_info}[2],     $invalid_target,                '... the links invalid target' );
            }

        }
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
