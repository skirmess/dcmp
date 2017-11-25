#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;
use Test::TempDir::Tiny;

use Cwd qw(cwd);
use Encode;
use File::Spec;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

    if ( $^O ne 'MSWin32' ) {
        push @suffixes, "a\nb";
    }

    for my $dir_l_suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "left dir suffix: $dir_l_suffix" ) );

        for my $dir_r_suffix (@suffixes) {
            note(q{----------------------------------------------------------});
            note( encode( 'UTF-8', "right dir suffix: $dir_r_suffix" ) );

            for my $file_suffix (@suffixes) {
                note(q{----------------------------------------------------------});
                note( encode( 'UTF-8', "file suffix: $file_suffix" ) );

                my $dir_1 = File::Spec->catdir( tempdir(), "dir1${dir_l_suffix}" );
                mkdir encode( 'UTF-8', $dir_1 );
                my $dir_2 = File::Spec->catdir( tempdir(), "dir2${dir_r_suffix}" );
                mkdir encode( 'UTF-8', $dir_2 );

                my $dcmp_filename_1 = "file1${file_suffix}.dcmp";
                my $dcmp_filename_2 = "file2${file_suffix}.dcmp";

                my $dir                     = _normalize_filename("dir${file_suffix}");
                my $dir_escaped             = App::DCMP::_escape_filename($dir);
                my $file                    = _normalize_filename("file${file_suffix}.txt");
                my $file_escaped            = App::DCMP::_escape_filename($file);
                my $file2                   = _normalize_filename("file2${file_suffix}.txt");
                my $file2_escaped           = App::DCMP::_escape_filename($file2);
                my $invalid_link            = _normalize_filename("invalid_link${file_suffix}.txt");
                my $invalid_link_escaped    = App::DCMP::_escape_filename($invalid_link);
                my $invalid_target          = _normalize_filename("invalid_target${file_suffix}.txt");
                my $invalid_target_escaped  = App::DCMP::_escape_filename($invalid_target);
                my $invalid_target2         = _normalize_filename("invalid_target2${file_suffix}.txt");
                my $invalid_target2_escaped = App::DCMP::_escape_filename($invalid_target2);
                my $valid_link              = _normalize_filename("valid_link${file_suffix}.txt");
                my $valid_link_escaped      = App::DCMP::_escape_filename($valid_link);
                my $valid_link2             = _normalize_filename("valid_link2${file_suffix}.txt");
                my $valid_link2_escaped     = App::DCMP::_escape_filename($valid_link2);

                my $dcmp_file_1 = File::Spec->catfile( $dir_1, $dcmp_filename_1 );
                open my $fh, '>:encoding(UTF-8)', encode( 'UTF-8', $dcmp_file_1 );
                print {$fh} <<"RECORD_FILE";
LINK $invalid_link_escaped $invalid_target_escaped
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
LINK $valid_link_escaped $file_escaped
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
-DIR
RECORD_FILE
                close $fh;

                my $it_l = App::DCMP::_load_dcmp_file($dcmp_file_1);
                is( ref $it_l, ref sub { }, '_load_records() returns a sub' );

                #
                my $dcmp_file_2 = File::Spec->catfile( $dir_2, $dcmp_filename_2 );
                open $fh, '>:encoding(UTF-8)', encode( 'UTF-8', $dcmp_file_2 );
                print {$fh} <<'RECORD_FILE';
-DIR
RECORD_FILE
                close $fh;

                #
                my $it_r = App::DCMP::_load_dcmp_file($dcmp_file_2);
                is( ref $it_r, ref sub { }, '_load_records() returns a sub' );

                #
                my $compare_file = sub { App::DCMP::_compare_file_record_record(@_) };

                my @output;
                my $printer = sub {
                    my ( $action, $dirs_ref, $name ) = @_;
                    push @output, [ $action, File::Spec->catdir( @{$dirs_ref}, $name ) ];
                    return;
                };

                is( App::DCMP::_dcmp( $it_l, $it_r, $compare_file, $printer ), undef, '_dcmp returns undef' );

                my @output_expected = sort { $a->[1] cmp $b->[1] } (
                    [ App::DCMP::FILE_ADDITIONAL(), $dir ],
                    [ App::DCMP::FILE_ADDITIONAL(), File::Spec->catfile( $dir, $file2 ) ],
                    [ App::DCMP::FILE_ADDITIONAL(), $file ],
                    [ App::DCMP::FILE_ADDITIONAL(), $invalid_link ],
                    [ App::DCMP::FILE_ADDITIONAL(), $valid_link ],
                );

                is_deeply( \@output, \@output_expected, '... and prints the correct output' );

                # ----------------------------------------------------------
                open $fh, '>:encoding(UTF-8)', encode( 'UTF-8', $dcmp_file_2 );
                print {$fh} <<"RECORD_FILE";
LINK $invalid_link_escaped $invalid_target_escaped
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
LINK $valid_link_escaped $file_escaped
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
-DIR
RECORD_FILE
                close $fh;

                $it_r = App::DCMP::_load_dcmp_file($dcmp_file_2);
                is( ref $it_r, ref sub { }, '_load_records() returns a sub' );

                undef @output;

                is( App::DCMP::_dcmp( $it_l, $it_r, $compare_file, $printer ), undef, '_dcmp returns undef' );

                @output_expected = ();

                is_deeply( \@output, \@output_expected, '... and prints the correct output' );

                # ----------------------------------------------------------
                open $fh, '>:encoding(UTF-8)', encode( 'UTF-8', $dcmp_file_2 );
                print {$fh} <<"RECORD_FILE";
LINK $invalid_link_escaped $invalid_target2_escaped
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9810998ecf8427e
-DIR
LINK $valid_link2_escaped $file_escaped
FILE $file_escaped 13 6f5902ac237024bdd0c176cb93063dc4
-DIR
RECORD_FILE
                close $fh;

                $it_r = App::DCMP::_load_dcmp_file($dcmp_file_2);
                is( ref $it_r, ref sub { }, '_load_records() returns a sub' );

                undef @output;

                is( App::DCMP::_dcmp( $it_l, $it_r, $compare_file, $printer ), undef, '_dcmp returns undef' );

                @output_expected = sort { $a->[1] cmp $b->[1] } (
                    [ App::DCMP::FILE_CONTENT_DIFFERS(), File::Spec->catfile( $dir, $file2 ) ],
                    [ App::DCMP::FILE_CONTENT_DIFFERS(), $file ],
                    [ App::DCMP::LINK_TARGET_DIFFERS(),  $invalid_link ],
                    [ App::DCMP::FILE_ADDITIONAL(),      $valid_link ],
                    [ App::DCMP::FILE_MISSING(),         $valid_link2 ],
                );

                is_deeply( \@output, \@output_expected, '... and prints the correct output' );
            }
        }
    }

    done_testing();

    exit 0;
}

# If the OS/filesystem normalizes the Unicode file name, the file name read
# with readdir might return a UTF-8 string that differs from the UTF-8 string
# that was used to create the file. OS/X does that. This function is used to
# normalize the file name in the same way.
{
    my %normalized_filename;

    sub _normalize_filename {
        my ($filename) = @_;

        if ( !exists $normalized_filename{$filename} ) {
            my $tmpdir  = tempdir();
            my $basedir = cwd();

            chdir $tmpdir;
            open my $fh, '>', encode( 'UTF-8', $filename );
            close $fh;

            opendir $fh, q{.};
            my @dents = grep { $_ ne q{.} && $_ ne q{..} } readdir $fh;
            closedir $fh;

            chdir $basedir;

            die encode( 'UTF-8', "Expected a single file in $tmpdir but got " . scalar(@dents) . " for $filename: " . join( q{ }, @dents ) . "\n" ) if @dents != 1;

            $normalized_filename{$filename} = decode( 'UTF-8', $dents[0] );
        }

        return $normalized_filename{$filename};
    }
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
