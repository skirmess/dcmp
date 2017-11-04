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

    # ----------------------------------------------------------
    my $tmpdir = tempdir();
    chdir $tmpdir;

    # cwd returns Unix dir separator on Windows but tempdir returns
    # Windows path separator on Windows. The error message in dcmp is
    # generated with cwd.
    $tmpdir = cwd();

    # ----------------------------------------------------------
    open my $fh, '>', 'file.txt';
    print {$fh} "hello world\n";
    close $fh;
    my $file_size = -s 'file.txt';
    my $md5       = Digest::MD5->new();
    $md5->add("hello world\n");
    my $md5_sum = lc $md5->hexdigest();

    # ----------------------------------------------------------
    open $fh, '>:encoding(UTF-8)', 'file_utf8.txt';
    print {$fh} "hello world\n\x{20ac}\n\x{00C0}\n\x{0041}\x{0300}";
    close $fh;
    my $file_utf8_size = -s 'file_utf8.txt';
    $md5 = Digest::MD5->new();
    $md5->add( encode( 'UTF-8', "hello world\n\x{20ac}\n\x{00C0}\n\x{0041}\x{0300}" ) );
    my $md5_utf8_sum = lc $md5->hexdigest();

    # ----------------------------------------------------------
    mkdir 'dir';

    # ----------------------------------------------------------
    like( exception { App::DCMP::_collect_file_info_report('invalid_file') }, "/ ^ \QCannot stat file invalid_file in $tmpdir: \E /xsm", '_collect_file_info_report throws an exception if stat failes' );

    # ----------------------------------------------------------
    open $fh, '>', 'invalid_file';
    close $fh;
    chmod 0, 'invalid_file';

    # ----------------------------------------------------------
    like( exception { App::DCMP::_collect_file_info_report('invalid_file') }, "/ ^ \QCannot read file invalid_file in $tmpdir: \E /xsm", '_collect_file_info_report throws an exception if it cannot read the file' );

    # ----------------------------------------------------------
    note('dir');
    my $file_info = App::DCMP::_collect_file_info_report('dir');
    is( ref $file_info, ref [], '_collect_file_info_report() returns am array ref' );
    is( scalar @{$file_info}, 2,                                '... consisting of two values' );
    is( ${$file_info}[0],     'dir',                            '... the file name' );
    is( ${$file_info}[1],     App::DCMP::FILE_TYPE_DIRECTORY(), '... the type (directory)' );

    # ----------------------------------------------------------
    note('file.txt');
    $file_info = App::DCMP::_collect_file_info_report('file.txt');
    is( ref $file_info, ref [], '_collect_file_info_report() returns am array ref' );
    is( scalar @{$file_info}, 4,                              '... consisting of four values' );
    is( ${$file_info}[0],     'file.txt',                     '... the file name' );
    is( ${$file_info}[1],     App::DCMP::FILE_TYPE_REGULAR(), '... the type (regular)' );
    is( ${$file_info}[2],     $file_size,                     '... the file size' );
    is( ${$file_info}[3],     $md5_sum,                       '... the md5 sum' );

    # ----------------------------------------------------------
    note('file_utf8.txt');
    $file_info = App::DCMP::_collect_file_info_report('file_utf8.txt');
    is( ref $file_info, ref [], '_collect_file_info_report() returns am array ref' );
    is( scalar @{$file_info}, 4,                              '... consisting of four values' );
    is( ${$file_info}[0],     'file_utf8.txt',                '... the file name' );
    is( ${$file_info}[1],     App::DCMP::FILE_TYPE_REGULAR(), '... the type (regular)' );
    is( ${$file_info}[2],     $file_utf8_size,                '... the file size' );
    is( ${$file_info}[3],     $md5_utf8_sum,                  '... the md5 sum' );

  SKIP: {
        {
            no autodie;
            skip 'The symlink function is unimplemented' if !eval { symlink q{}, q{}; 1 };
        }
        symlink 'file.txt',           'valid_link.txt';
        symlink 'invalid_target.txt', 'invalid_link.txt';

        # ----------------------------------------------------------
        note('valid_link.txt');
        $file_info = App::DCMP::_collect_file_info_report('valid_link.txt');
        is( ref $file_info, ref [], '_collect_file_info_report() returns am array ref' );
        is( scalar @{$file_info}, 3,                              '... consisting of three values' );
        is( ${$file_info}[0],     'valid_link.txt',               '... the file name' );
        is( ${$file_info}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... the tyoe (symlink)' );
        is( ${$file_info}[2],     'file.txt',                     '... the links valid target' );

        # ----------------------------------------------------------
        note('invalid_link.txt');
        $file_info = App::DCMP::_collect_file_info_report('invalid_link.txt');
        is( ref $file_info, ref [], '_collect_file_info_report() returns am array ref' );
        is( scalar @{$file_info}, 3,                              '... consisting of three values' );
        is( ${$file_info}[0],     'invalid_link.txt',             '... the file name' );
        is( ${$file_info}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... the type (symlink)' );
        is( ${$file_info}[2],     'invalid_target.txt',           '... the links invalid target' );
    }

    # ----------------------------------------------------------
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
