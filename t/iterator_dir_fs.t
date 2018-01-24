#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd qw(cwd);
use Encode;

use lib qw(.);

use FindBin qw($Bin);
use lib "$Bin/lib";

use Local::Normalize_Filename;
use Local::Suffixes;
use Local::Symlink;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $collect_file_info = sub {
        App::DCMP::_collect_file_info(@_);
    };

    my $basedir = cwd();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix_text" ) );

        {
            my $file_a    = "a${suffix_bin}.txt";
            my $file_b    = "b${suffix_bin}.txt";
            my $dir_c     = "c${suffix_bin}";
            my $symlink_d = "d${suffix_bin}.txt";

            note('setup configuration for tests with empty @dirs');
            my $tmpdir = tempdir();

            chdir $tmpdir;
            open my $fh, '>', $file_a;
            close $fh;

            open $fh, '>', $file_b;
            print {$fh} "hello world\n";
            close $fh;
            my $file_size = -s $file_b;

            mkdir $dir_c;

            if ( Local::Symlink::symlink_supported() ) {
                symlink $file_a, $symlink_d;
            }

            chdir $basedir;

            my $chdir = sub {
                App::DCMP::_chdir( $tmpdir, @_ );
            };

            my @dirs;

            my $ignore = App::DCMP::_ignored( [], [] );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            my $it = App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, $ignore, \@dirs );
            is( ref $it, ref sub { }, '_iterator_dir_fs() returns a sub' );

            #
            note('first file info');
            my $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 3, '... consisting of three values' );
            is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_a), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
            is( ${$file_info}[2], 0, '... the file size' );

            #
            note('second file info');
            $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 3, '... consisting of three values' );
            is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_b), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
            is( ${$file_info}[2], $file_size, '... the file size' );

            #
            note('third file info');
            $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 2, '... consisting of two values' );
            is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($dir_c), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );

            if ( Local::Symlink::symlink_supported() ) {
                #
                note('fourth file info');
                $file_info = $it->();
                is( ref $file_info, ref [], 'file info is an array ref' );
                is( scalar @{$file_info}, 3, '... consisting of three values' );
                is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($symlink_d), '... the file name' );
                like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                is( ${$file_info}[1], App::DCMP::FILE_TYPE_SYMLINK(), '... which is from a symlink' );
                is( ${$file_info}[2], $file_a, '... the links target' );
            }
        }

        {
            my $file_aa    = "AA${suffix_bin}.txt";
            my $file_bb    = "BB${suffix_bin}.txt";
            my $dir_cc     = "CC${suffix_bin}";
            my $symlink_dd = "DD${suffix_bin}.txt";

            my $tmpdir = tempdir();
            my $chdir  = sub {
                App::DCMP::_chdir( $tmpdir, @_ );
            };

            #
            note('setup tests for 26 directories in @dir');
            chdir $tmpdir;
            my @dirs = map { "$_${suffix_bin}" } 'a' .. 'z';
            for my $d (@dirs) {
                mkdir $d;
                chdir $d;
            }

            open my $fh, '>', $file_aa;
            close $fh;

            open $fh, '>', $file_bb;
            print {$fh} "hello world\n";
            close $fh;
            my $file_size = -s $file_bb;

            mkdir $dir_cc;

            if ( Local::Symlink::symlink_supported() ) {
                symlink $file_aa, $symlink_dd;
            }

            chdir $basedir;

            my $ignore = App::DCMP::_ignored( [], [] );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            my $it = App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, $ignore, \@dirs );
            is( ref $it, ref sub { }, '_iterator_dir_fs() returns a sub' );

            #
            note('first file info');
            my $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 3, '... consisting of three values' );
            is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_aa), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
            is( ${$file_info}[2], 0, '... the file size' );

            #
            note('second file info');
            $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 3, '... consisting of three values' );
            is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_bb), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
            is( ${$file_info}[2], $file_size, '... the file size' );

            #
            note('third file info');
            $file_info = $it->();
            is( ref $file_info, ref [], 'file info is an array ref' );
            is( scalar @{$file_info}, 2, '... consisting of two values' );
            is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($dir_cc), '... the file name' );
            like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
            is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );

            if ( Local::Symlink::symlink_supported() ) {
                #
                note('fourth file info');
                $file_info = $it->();
                is( ref $file_info, ref [], 'file info is an array ref' );
                is( scalar @{$file_info}, 3, '... consisting of three values' );
                is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($symlink_dd), '... the file name' );
                like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                is( ${$file_info}[1], App::DCMP::FILE_TYPE_SYMLINK(), '... which is from a symlink' );
                is( ${$file_info}[2], $file_aa, '... the links target' );
            }
        }

        {
            #
            note('ignore some dirs');
            my $tmpdir = tempdir();

            chdir $tmpdir;

            my $dir_a  = "a${suffix_bin}";
            my $dir_b  = "b${suffix_bin}";
            my $dir_c  = "c${suffix_bin}";
            my $file_d = "d${suffix_bin}.txt";

            mkdir $dir_a;
            mkdir $dir_b;
            mkdir $dir_c;

            open my $fh, '>', $file_d;
            close $fh;

            chdir $basedir;

            my $chdir = sub {
                App::DCMP::_chdir( $tmpdir, @_ );
            };

            my @dirs;

            for my $state ( 0 .. 3 ) {
                my @ignore =
                    $state == 0 ? ()
                  : $state == 1 ? ( Local::Normalize_Filename::normalize_filename($dir_a) )
                  : $state == 2 ? ( Local::Normalize_Filename::normalize_filename($dir_a), Local::Normalize_Filename::normalize_filename($dir_b) )
                  : $state == 3 ? ( Local::Normalize_Filename::normalize_filename($dir_a), Local::Normalize_Filename::normalize_filename($dir_b), Local::Normalize_Filename::normalize_filename($file_d) )
                  :               BAIL_OUT 'internal error';

                if ( !@ignore ) {
                    note(q{### @ignore = ()});
                }
                else {
                    note( encode( 'UTF-8', q{### @ignore = ('} . join( q{', '}, @ignore ) . q{')} ) );
                }

                my $ignore = App::DCMP::_ignored( [], \@ignore );
                is( ref $ignore, ref sub { }, '_ignore returns a sub' );

                my $it = App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, $ignore, \@dirs );
                is( ref $it, ref sub { }, '_iterator_dir_fs() returns a sub' );

                #
                my $file_info;
                if ( $state == 0 ) {
                    note( encode( 'UTF-8', $dir_a ) );
                    $file_info = $it->();
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 2, '... consisting of three values' );
                    is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($dir_a), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );
                }

                if ( $state < 2 ) {
                    note( encode( 'UTF-8', $dir_b ) );
                    $file_info = $it->();
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 2, '... consisting of three values' );
                    is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($dir_b), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );
                }

                note( encode( 'UTF_8', $dir_c ) );
                $file_info = $it->();
                is( ref $file_info, ref [], 'file info is an array ref' );
                is( scalar @{$file_info}, 2, '... consisting of three values' );
                is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($dir_c), '... the file name' );
                like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );

                if ( $state < 3 ) {
                    note( encode( 'UTF-8', $file_d ) );
                    $file_info = $it->();
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 3, '... consisting of three values' );
                    is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_d), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                    is( ${$file_info}[2], 0, '... the file size' );
                }

                note('exhausted');
                is( $it->(), undef, 'iterator is exhausted' );
            }
        }

        {
            #
            note('ignore some path');
            my $tmpdir = tempdir();

            chdir $tmpdir;

            my $file_f = Local::Normalize_Filename::normalize_filename("f${suffix_bin}.txt");

            open my $fh, '>', $file_f;
            close $fh;

            my $dir_a = Local::Normalize_Filename::normalize_filename("a${suffix_bin}");
            mkdir $dir_a;
            chdir $dir_a;

            my $file_e = Local::Normalize_Filename::normalize_filename("e${suffix_bin}.txt");

            open $fh, '>', $file_e;
            close $fh;

            my $dir_b = Local::Normalize_Filename::normalize_filename("b${suffix_bin}");
            mkdir $dir_b;
            chdir $dir_b;

            my $dir_c = Local::Normalize_Filename::normalize_filename("c${suffix_bin}");
            mkdir $dir_c;
            chdir $dir_c;

            my $file_d = Local::Normalize_Filename::normalize_filename("d${suffix_bin}.txt");

            open $fh, '>', $file_d;
            close $fh;

            chdir $basedir;

            my $chdir = sub {
                App::DCMP::_chdir( $tmpdir, @_ );
            };

            for my $state ( 0 .. 5 ) {
                my @ignore =
                    $state == 0 ? ()
                  : $state == 1 ? ('no_such_dir')
                  : $state == 2 ? ( File::Spec->canonpath( File::Spec->catdir($dir_a) ) )
                  : $state == 3 ? ( File::Spec->canonpath( File::Spec->catdir( $dir_a, $dir_b ) ) )
                  : $state == 4 ? ( File::Spec->canonpath( File::Spec->catdir( $dir_a, $dir_b, $dir_c ) ) )
                  : $state == 5 ? ( 'no_such_dir', File::Spec->canonpath( File::Spec->catdir( $dir_a, $dir_b, $dir_c ) ) )
                  :               BAIL_OUT 'internal error';

                if ( !@ignore ) {
                    note(q{### @ignore = ()});
                }
                else {
                    note( encode( 'UTF-8', q{### @ignore = ('} . join( q{', '}, @ignore ) . q{')} ) );
                }

                my $ignore = App::DCMP::_ignored( \@ignore, [] );
                is( ref $ignore, ref sub { }, '_ignore returns a sub' );

                my @dirs;
                note(q{### @dirs = ()});

                my $it = App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, $ignore, \@dirs );
                is( ref $it, ref sub { }, '_iterator_dir_fs() returns a sub' );

                my $file_info;
                if ( $state != 2 ) {
                    note( encode( 'UTF-8', $dir_a ) );
                    $file_info = $it->();
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 2, '... consisting of three values' );
                    is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($dir_a), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );
                }

                $file_info = $it->();
                note( encode( 'UTF-8', $file_f ) );
                is( ref $file_info, ref [], 'file info is an array ref' );
                is( scalar @{$file_info}, 3, '... consisting of three values' );
                is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_f), '... the file name' );
                like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                is( ${$file_info}[2], 0, '... the file size' );

                note('exhausted');
                is( $it->(), undef, 'iterator is exhausted' );

                @dirs = ($dir_a);
                note( encode( 'UTF-8', q{### @dirs = ('} . join( q{', '}, @dirs ) . q{')} ) );

                $it = App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, $ignore, \@dirs );
                is( ref $it, ref sub { }, '_iterator_dir_fs() returns a sub' );

                if ( $state < 2 || $state > 3 ) {
                    note( encode( 'UTF-8', $dir_b ) );
                    $file_info = $it->();
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 2, '... consisting of three values' );
                    is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($dir_b), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_DIRECTORY(), '... which is from a directory' );
                }

                if ( $state != 2 ) {
                    note( encode( 'UTF-8', $file_e ) );
                    $file_info = $it->();
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 3, '... consisting of three values' );
                    is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_e), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                    is( ${$file_info}[2], 0, '... the file size' );
                }

                note('exhausted');
                is( $it->(), undef, 'iterator is exhausted' );

                @dirs = ( $dir_a, $dir_b, $dir_c );
                note( encode( 'UTF-8', q{### @dirs = ('} . join( q{', '}, @dirs ) . q{')} ) );

                $it = App::DCMP::_iterator_dir_fs( $chdir, $collect_file_info, $ignore, \@dirs );
                is( ref $it, ref sub { }, '_iterator_dir_fs() returns a sub' );

                if ( $state < 2 ) {
                    note( encode( 'UTF-8', $file_d ) );
                    $file_info = $it->();
                    is( ref $file_info, ref [], 'file info is an array ref' );
                    is( scalar @{$file_info}, 3, '... consisting of three values' );
                    is( ${$file_info}[0], Local::Normalize_Filename::normalize_filename($file_d), '... the file name' );
                    like( ${$file_info}[1], '/ ^ [0-9]+ $ /xsm', '... the mode' );
                    is( ${$file_info}[1], App::DCMP::FILE_TYPE_REGULAR(), '... which is from a file' );
                    is( ${$file_info}[2], 0, '... the file size' );
                }

                note('exhausted');
                is( $it->(), undef, 'iterator is exhausted' );

            }
        }
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
