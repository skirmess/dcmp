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

use constant TYPE_FS     => 1;
use constant TYPE_RECORD => 2;

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

                for my $symlink_supported ( _symlink_supported() ? ( 0, 1 ) : 0 ) {

                    note( 'symlink ' . ( $symlink_supported ? q{} : 'not ' ) . 'supported' );

                    for my $type1 ( TYPE_FS, TYPE_RECORD ) {

                        for my $type2 ( TYPE_FS, TYPE_RECORD ) {

                            note( 'mode: ' . ( $type1 == TYPE_FS ? 'FS' : 'RECORD' ) . q{/} . ( $type2 == TYPE_FS ? 'FS' : 'RECORD' ) );

                            # ----------------------------------------------------------
                            my @output;
                            my $printer = sub {
                                my ( $action, $dirs_ref, $name ) = @_;
                                push @output, [ $action, File::Spec->catdir( @{$dirs_ref}, $name ) ];
                                return;
                            };

                            # ----------------------------------------------------------

                            my $dcmp_filename_1         = "file1${file_suffix}.dcmp";
                            my $dcmp_filename_2         = "file2${file_suffix}.dcmp";
                            my $dir                     = _normalize_filename("dir${file_suffix}");
                            my $dir_escaped             = App::DCMP::_escape_filename($dir);
                            my $dir2                    = _normalize_filename("dir2${file_suffix}");
                            my $dir2_escaped            = App::DCMP::_escape_filename($dir2);
                            my $dir3                    = _normalize_filename("dir3${file_suffix}");
                            my $dir3_escaped            = App::DCMP::_escape_filename($dir3);
                            my $dir4                    = _normalize_filename("dir4${file_suffix}");
                            my $dir4_escaped            = App::DCMP::_escape_filename($dir4);
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

                            # ----------------------------------------------------------
                            my $dir_l = File::Spec->catdir( tempdir(), "dirL${dir_l_suffix}" );
                            mkdir encode( 'UTF-8', $dir_l );

                            my $chdir_l;
                            my $it_l;

                            if ( $type1 == TYPE_FS ) {
                                $chdir_l = sub { return App::DCMP::_chdir( $dir_l, @_ ); };

                                $it_l = sub {
                                    return App::DCMP::_iterator_dir_fs( $chdir_l, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                                };

                                if ($symlink_supported) {
                                    symlink encode( 'UTF-8', $invalid_target ), encode( 'UTF-8', File::Spec->catfile( $dir_l, $invalid_link ) );
                                }

                                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_l, $dir ) );

                                open my $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_l, $dir, $file2 ) );
                                close $fh;

                                if ($symlink_supported) {
                                    symlink encode( 'UTF-8', $file ), encode( 'UTF-8', File::Spec->catfile( $dir_l, $valid_link ) );
                                }

                                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_l, $file ) );
                                print {$fh} "hello world\n";
                                close $fh;
                            }
                            else {
                                my $dcmp_file_1 = File::Spec->catfile( $dir_l, $dcmp_filename_1 );
                                open my $fh, '>:encoding(UTF-8)', encode( 'UTF-8', $dcmp_file_1 );

                                print {$fh} <<"RECORD_FILE";
dcmp v1
LINK $invalid_link_escaped $invalid_target_escaped
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
LINK $valid_link_escaped $file_escaped
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
-DIR
RECORD_FILE
                                close $fh;

                                $it_l = App::DCMP::_load_dcmp_file($dcmp_file_1);
                                is( ref $it_l, ref sub { }, '_load_records() returns a sub' );
                            }

                            # ----------------------------------------------------------
                            my $dir_r = File::Spec->catdir( tempdir(), "dirR${dir_r_suffix}" );
                            mkdir encode( 'UTF-8', $dir_r );

                            my $chdir_r;
                            my $it_r;

                            if ( $type2 == TYPE_FS ) {
                                $chdir_r = sub { return App::DCMP::_chdir( $dir_r, @_ ); };

                                $it_r = sub {
                                    return App::DCMP::_iterator_dir_fs( $chdir_r, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                                };
                            }
                            else {
                                my $dcmp_file_2 = File::Spec->catfile( $dir_r, $dcmp_filename_2 );
                                open my $fh, '>:encoding(UTF-8)', encode( 'UTF-8', $dcmp_file_2 );
                                print {$fh} <<'RECORD_FILE';
dcmp v1
-DIR
RECORD_FILE
                                close $fh;

                                $it_r = App::DCMP::_load_dcmp_file($dcmp_file_2);
                                is( ref $it_r, ref sub { }, '_load_records() returns a sub' );
                            }

                            # ----------------------------------------------------------
                            my $compare_file;
                            if ( $type1 == TYPE_FS ) {
                                if ( $type2 == TYPE_FS ) {
                                    $compare_file = sub { App::DCMP::_COMPARE_FILE_fs_fs( $chdir_l, $chdir_r, @_ ) };
                                }
                                else {
                                    $compare_file = sub { @_[ -2, -1 ] = @_[ -1, -2 ]; App::DCMP::_COMPARE_FILE_record_fs( $chdir_l, @_ ) };
                                }
                            }
                            else {
                                if ( $type2 == TYPE_RECORD ) {
                                    $compare_file = sub { App::DCMP::_COMPARE_FILE_record_record(@_) };
                                }
                                else {
                                    $compare_file = sub { App::DCMP::_COMPARE_FILE_record_fs( $chdir_r, @_ ) };
                                }
                            }

                            # ----------------------------------------------------------

                            is( App::DCMP::_dcmp( $it_l, $it_r, $compare_file, $printer ), undef, '_dcmp returns undef' );

                            my @output_expected = sort { $a->[1] cmp $b->[1] } (
                                [ App::DCMP::FILE_ADDITIONAL(), $dir ],
                                [ App::DCMP::FILE_ADDITIONAL(), File::Spec->catfile( $dir, $file2 ) ],
                                [ App::DCMP::FILE_ADDITIONAL(), $file ],
                                ( $symlink_supported || $type1 == TYPE_RECORD )
                                ? (
                                    [ App::DCMP::FILE_ADDITIONAL(), $invalid_link ],
                                    [ App::DCMP::FILE_ADDITIONAL(), $valid_link ],
                                  )
                                : (),
                            );

                            is_deeply( \@output, \@output_expected, '... and prints the correct output' );

                            # ----------------------------------------------------------
                            $dir_r = File::Spec->catdir( tempdir(), "dirR${dir_r_suffix}" );
                            mkdir encode( 'UTF-8', $dir_r );

                            if ( $type2 == TYPE_FS ) {
                                $chdir_r = sub { return App::DCMP::_chdir( $dir_r, @_ ); };

                                $it_r = sub {
                                    return App::DCMP::_iterator_dir_fs( $chdir_r, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                                };

                                if ($symlink_supported) {
                                    symlink encode( 'UTF-8', $invalid_target ), encode( 'UTF-8', File::Spec->catfile( $dir_r, $invalid_link ) );
                                }

                                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir ) );

                                open my $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_r, $dir, $file2 ) );
                                close $fh;

                                if ($symlink_supported) {
                                    symlink encode( 'UTF-8', $file ), encode( 'UTF-8', File::Spec->catfile( $dir_r, $valid_link ) );
                                }

                                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_r, $file ) );
                                print {$fh} "hello world\n";
                                close $fh;
                            }
                            else {
                                my $dcmp_file_2 = File::Spec->catfile( $dir_r, $dcmp_filename_2 );
                                open my $fh, '>:encoding(UTF-8)', encode( 'UTF-8', $dcmp_file_2 );
                                print {$fh} <<"RECORD_FILE";
dcmp v1
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
                            }

                            undef @output;

                            is( App::DCMP::_dcmp( $it_l, $it_r, $compare_file, $printer ), undef, '_dcmp returns undef' );

                            if ( !$symlink_supported && $type1 == TYPE_FS && $type2 == TYPE_RECORD ) {
                                @output_expected = (
                                    [ App::DCMP::FILE_MISSING(), $invalid_link ],
                                    [ App::DCMP::FILE_MISSING(), $valid_link ],
                                );
                            }
                            elsif ( !$symlink_supported && $type1 == TYPE_RECORD && $type2 == TYPE_FS ) {
                                @output_expected = (
                                    [ App::DCMP::FILE_ADDITIONAL(), $invalid_link ],
                                    [ App::DCMP::FILE_ADDITIONAL(), $valid_link ],
                                );
                            }
                            else {
                                @output_expected = ();
                            }

                            is_deeply( \@output, \@output_expected, '... and prints the correct output' );

                            # ----------------------------------------------------------
                            if ( $type1 == TYPE_FS ) {
                                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_l, $dir4 ) );

                                open my $fh, '>', encode( 'UTF-8', File::Spec->catdir( $dir_l, $dir4, $file ) );
                                close $fh;

                                # yes, dir3 as file for different type!
                                open $fh, '>', encode( 'UTF-8', File::Spec->catdir( $dir_l, $dir3 ) );
                                close $fh;
                            }
                            else {
                                my $dcmp_file_1 = File::Spec->catfile( $dir_r, $dcmp_filename_1 );
                                open my $fh, '>:encoding(UTF-8)', encode( 'UTF-8', $dcmp_file_1 );
                                print {$fh} <<"RECORD_FILE";
dcmp v1
LINK $invalid_link_escaped $invalid_target_escaped
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
LINK $valid_link_escaped $file_escaped
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
FILE $dir3_escaped 0 aaaaaa
DIR $dir4_escaped
FILE $file_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
-DIR
RECORD_FILE
                                close $fh;

                                $it_l = App::DCMP::_load_dcmp_file($dcmp_file_1);
                                is( ref $it_l, ref sub { }, '_load_records() returns a sub' );
                            }

                            if ( $type2 == TYPE_FS ) {
                                $dir_r = File::Spec->catdir( tempdir(), "dirR${dir_r_suffix}" );
                                mkdir encode( 'UTF-8', $dir_r );

                                $chdir_r = sub { return App::DCMP::_chdir( $dir_r, @_ ); };

                                $it_r = sub {
                                    return App::DCMP::_iterator_dir_fs( $chdir_r, sub { return App::DCMP::_collect_file_info(@_); }, undef, @_ );
                                };

                                if ($symlink_supported) {
                                    symlink encode( 'UTF-8', $invalid_target2 ), encode( 'UTF-8', File::Spec->catfile( $dir_r, $invalid_link ) );
                                }

                                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir ) );

                                open my $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_r, $dir, $file2 ) );
                                print {$fh} "test\n";
                                close $fh;

                                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir2 ) );

                                open $fh, '>', encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir2, $file2 ) );
                                close $fh;

                                if ($symlink_supported) {
                                    symlink encode( 'UTF-8', $file ), encode( 'UTF-8', File::Spec->catfile( $dir_r, $valid_link2 ) );
                                }

                                open $fh, '>', encode( 'UTF-8', File::Spec->catfile( $dir_r, $file ) );
                                print {$fh} "\nhello world\n";
                                close $fh;

                                mkdir encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir3 ) );

                                open $fh, '>', encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir3, $file2 ) );
                                close $fh;

                                # yes, dir4 as file for different type!
                                open $fh, '>', encode( 'UTF-8', File::Spec->catdir( $dir_r, $dir4 ) );
                                close $fh;
                            }
                            else {
                                my $dcmp_file_2 = File::Spec->catfile( $dir_r, $dcmp_filename_2 );
                                open my $fh, '>:encoding(UTF-8)', encode( 'UTF-8', $dcmp_file_2 );
                                print {$fh} <<"RECORD_FILE";
dcmp v1
LINK $invalid_link_escaped $invalid_target2_escaped
LINK $valid_link2_escaped $file_escaped
DIR $dir2_escaped
FILE $file2_escaped 13 6f5902ac237024bdd0c176cb93063dc4
-DIR
FILE $file_escaped 13 6f5902ac237024bdd0c176cb93063dc4
FILE $dir4_escaped 0 aaaaa
DIR $dir_escaped
FILE $file2_escaped 13 6f5902ac237024bdd0c176cb93063dc4
-DIR
DIR $dir3_escaped
FILE $file2_escaped 13 6f5902ac237024bdd0c176cb93063dc4
-DIR
-DIR
RECORD_FILE
                                close $fh;

                                $it_r = App::DCMP::_load_dcmp_file($dcmp_file_2);
                                is( ref $it_r, ref sub { }, '_load_records() returns a sub' );
                            }

                            # --------------------------------------------------
                            undef @output;

                            is( App::DCMP::_dcmp( $it_l, $it_r, $compare_file, $printer ), undef, '_dcmp returns undef' );

                            @output_expected = (
                                [ App::DCMP::FILE_CONTENT_DIFFERS(), File::Spec->catfile( $dir,  $file2 ) ],
                                [ App::DCMP::FILE_MISSING(),         $dir2 ],
                                [ App::DCMP::FILE_MISSING(),         File::Spec->catfile( $dir2, $file2 ) ],
                                [ App::DCMP::FILE_TYPE_DIFFERS(),    $dir3 ],
                                [ App::DCMP::FILE_MISSING(),         File::Spec->catfile( $dir3, $file2 ) ],
                                [ App::DCMP::FILE_TYPE_DIFFERS(),    $dir4 ],
                                [ App::DCMP::FILE_ADDITIONAL(),      File::Spec->catfile( $dir4, $file ) ],
                                [ App::DCMP::FILE_CONTENT_DIFFERS(), $file ],
                            );

                            if ( $symlink_supported || ( ( $type1 == TYPE_RECORD ) && ( $type2 == TYPE_RECORD ) ) ) {
                                push @output_expected,
                                  [ App::DCMP::LINK_TARGET_DIFFERS(), $invalid_link ],
                                  [ App::DCMP::FILE_ADDITIONAL(),     $valid_link ],
                                  [ App::DCMP::FILE_MISSING(),        $valid_link2 ];
                            }
                            elsif ( ( !$symlink_supported ) && ( $type1 == TYPE_RECORD ) ) {

                                # symlink from dcmp file are present, the ones on the filesystem are not
                                push @output_expected,
                                  [ App::DCMP::FILE_ADDITIONAL(), $invalid_link ],
                                  [ App::DCMP::FILE_ADDITIONAL(), $valid_link ];
                            }
                            elsif ( ( !$symlink_supported ) && ( $type2 == TYPE_RECORD ) ) {

                                # symlink from dcmp file are present, the ones on the filesystem are not
                                push @output_expected,
                                  [ App::DCMP::FILE_MISSING(), $invalid_link ],
                                  [ App::DCMP::FILE_MISSING(), $valid_link2 ];
                            }

                            @output_expected = sort { $a->[1] cmp $b->[1] } @output_expected;

                            is_deeply( \@output, \@output_expected, '... and prints the correct output' );

                        }
                    }
                }
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

sub _symlink_supported {
    my $symlink_supported = 0;

    no autodie;

    eval {
        symlink q{}, q{};
        $symlink_supported = 1;
    };

    return $symlink_supported;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
