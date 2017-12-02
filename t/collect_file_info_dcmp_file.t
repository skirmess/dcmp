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

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Suffixes;
use Local::Symlink;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        my $dir               = "dir${suffix_bin}";
        my $dir_text          = "dir${suffix_text}";
        my $file              = "file${suffix_bin}.txt";
        my $file_text         = "file${suffix_text}.txt";
        my $file2             = "file2${suffix_bin}.txt";
        my $file2_text        = "file2${suffix_text}.txt";
        my $invalid_file      = "invalid_file${suffix_bin}.txt";
        my $invalid_link      = "invalid_link${suffix_bin}.txt";
        my $invalid_link_text = "invalid_link${suffix_text}.txt";
        my $invalid_target    = "invalid_target${suffix_bin}.txt";
        my $valid_link        = "valid_link${suffix_bin}.txt";
        my $valid_link_text   = "valid_link${suffix_text}.txt";

        my $dir_suffix_iterator = Local::Suffixes::suffix_iterator();

        while ( my ( $dir_suffix_text, $dir_suffix_bin ) = $dir_suffix_iterator->() ) {
            note(q{----------------------------------------------------------});
            note( encode( 'UTF-8', "dir suffix: $dir_suffix_text" ) );

            # ----------------------------------------------------------
            my $tmpdir = tempdir();
            chdir $tmpdir;

            my $ws = "ws$dir_suffix_bin";
            mkdir $ws;
            chdir $ws;

            # cwd returns Unix dir separator on Windows but tempdir returns
            # Windows path separator on Windows. The error message in dcmp is
            # generated with cwd.
            $tmpdir = cwd();

            # ----------------------------------------------------------
            open my $fh, '>', $file;
            print {$fh} 'hello world';
            close $fh;
            my $file_size = -s $file;
            my $md5       = Digest::MD5->new();
            $md5->add('hello world');
            my $md5_sum = lc $md5->hexdigest();

            # ----------------------------------------------------------
            open $fh, '>:encoding(UTF-8)', $file2;
            print {$fh} "hello world\t\x{20ac}\t\x{00C0}\t\x{0041}\x{0300}";
            close $fh;
            my $file_utf8_size = -s $file2;
            $md5 = Digest::MD5->new();
            $md5->add( encode( 'UTF-8', "hello world\t\x{20ac}\t\x{00C0}\t\x{0041}\x{0300}" ) );
            my $md5_utf8_sum = lc $md5->hexdigest();

            # ----------------------------------------------------------
            mkdir $dir;

            # ----------------------------------------------------------
            like( exception { App::DCMP::_collect_file_info_dcmp_file($invalid_file) }, "/ ^ \QCannot stat file $invalid_file in $tmpdir: \E /xsm", '_collect_file_info_dcmp_file throws an exception if stat failes' );

            # ----------------------------------------------------------
            note( encode( 'UTF-8', $dir_text ) );
            my $file_info = App::DCMP::_collect_file_info_dcmp_file($dir);
            is( ref $file_info, ref [], '_collect_file_info_dcmp_file() returns am array ref' );
            is( scalar @{$file_info}, 2,                                '... consisting of two values' );
            is( ${$file_info}[0],     $dir,                             '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_DIRECTORY(), '... the type (directory)' );

            # ----------------------------------------------------------
            note( encode( 'UTF-8', $file_text ) );
            $file_info = App::DCMP::_collect_file_info_dcmp_file($file);
            is( ref $file_info, ref [], '_collect_file_info_dcmp_file() returns am array ref' );
            is( scalar @{$file_info}, 4,                              '... consisting of four values' );
            is( ${$file_info}[0],     $file,                          '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_REGULAR(), '... the type (regular)' );
            is( ${$file_info}[2],     $file_size,                     '... the file size' );
            is( ${$file_info}[3],     $md5_sum,                       '... the md5 sum' );

            # ----------------------------------------------------------
            note( encode( 'UTF-8', $file2_text ) );
            $file_info = App::DCMP::_collect_file_info_dcmp_file($file2);
            is( ref $file_info, ref [], '_collect_file_info_dcmp_file() returns am array ref' );
            is( scalar @{$file_info}, 4,                              '... consisting of four values' );
            is( ${$file_info}[0],     $file2,                         '... the file name' );
            is( ${$file_info}[1],     App::DCMP::FILE_TYPE_REGULAR(), '... the type (regular)' );
            is( ${$file_info}[2],     $file_utf8_size,                '... the file size' );
            is( ${$file_info}[3],     $md5_utf8_sum,                  '... the md5 sum' );

          SKIP: {
                skip 'The symlink function is unimplemented' if !Local::Symlink::symlink_supported();

                symlink $file,           $valid_link;
                symlink $invalid_target, $invalid_link;

                # ----------------------------------------------------------
                note( encode( 'UTF-8', $valid_link_text ) );
                $file_info = App::DCMP::_collect_file_info_dcmp_file($valid_link);
                is( ref $file_info, ref [], '_collect_file_info_dcmp_file() returns am array ref' );
                is( scalar @{$file_info}, 3,                              '... consisting of three values' );
                is( ${$file_info}[0],     $valid_link,                    '... the file name' );
                is( ${$file_info}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... the tyoe (symlink)' );
                is( ${$file_info}[2],     $file,                          '... the links valid target' );

                # ----------------------------------------------------------
                note( encode( 'UTF-8', $invalid_link_text ) );
                $file_info = App::DCMP::_collect_file_info_dcmp_file($invalid_link);
                is( ref $file_info, ref [], '_collect_file_info_dcmp_file() returns am array ref' );
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
