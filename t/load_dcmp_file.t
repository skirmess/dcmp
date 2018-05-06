#!perl

use 5.006;
use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Encode;
use File::Spec;

use lib qw(.);

use FindBin qw($RealBin);
use lib "$RealBin/lib";

use Local::Suffixes;
use Local::Test::Util;

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my $suffix_iterator = Local::Suffixes::suffix_iterator();
    my $test            = Local::Test::Util->new;

    while ( my ( $suffix_text, $suffix_bin ) = $suffix_iterator->() ) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix = $suffix_text" ) );

        my $dcmp_file = File::Spec->catfile( tempdir(), "file${suffix_bin}.dcmp" );

        my $ignore = App::DCMP::_ignored( [], [] );
        is( ref $ignore, ref sub { }, '_ignore returns a sub' );

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ) }, "/ ^ \QCannot read file $dcmp_file: \E /xsm", '_load_dcmp_file throws an exception if the dcmp file cannot be read' );

        my $dir                    = "dir${suffix_bin}";
        my $dir_text               = "dir${suffix_text}";
        my $dir_escaped            = App::DCMP::_escape_filename($dir);
        my $file                   = "file${suffix_bin}.txt";
        my $file_escaped           = App::DCMP::_escape_filename($file);
        my $file2                  = "file2${suffix_bin}.txt";
        my $file2_escaped          = App::DCMP::_escape_filename($file2);
        my $invalid_link           = "invalid_link${suffix_bin}.txt";
        my $invalid_link_escaped   = App::DCMP::_escape_filename($invalid_link);
        my $invalid_target         = "invalid_target${suffix_bin}.txt";
        my $invalid_target_escaped = App::DCMP::_escape_filename($invalid_target);
        my $valid_link             = "valid_link${suffix_bin}.txt";
        my $valid_link_escaped     = App::DCMP::_escape_filename($valid_link);

        #
        note('no version in dcmp file');

        $test->touch( $dcmp_file, <<'RECORD_FILE');
-DIR
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ) }, "/ ^ \QFile $dcmp_file is not a valid dcmp file\E \$ /xsm", '_load_dcmp_file() throws an exception if the dcmp file contains no version header' );

        #
        note('invalid enty in dcmp file');

        $test->touch( $dcmp_file, <<'RECORD_FILE');
dcmp v1
INVALID entry
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ) }, "/ ^ \QInvalid entry on line 2 in file $dcmp_file\E \$ /xsm", '_load_dcmp_file() throws an exception if the dcmp file contains an invalid entry' );

        #
        note('to many -DIR in dcmp file');

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
-DIR
LINK $invalid_link_escaped $invalid_target_escaped
LINK $valid_link_escaped $file_escaped
-DIR
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ); }, "/ ^ \QUnbalanced -DIR on line 6 in file $dcmp_file\E \$ /xsm", q{_load_dcmp_file() throws an exception if there are to many '-DIR'} );

        #
        note('missing -DIR at end in dcmp file');

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
LINK $invalid_link_escaped $invalid_target_escaped
LINK $valid_link_escaped $file_escaped
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ); }, "/ ^ \QUnbalanced -DIR at end of file $dcmp_file\E \$ /xsm", q{_load_dcmp_file() throws an exception if there are to few '-DIR'} );

        #
        note('duplicate file in directory');

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
LINK $invalid_link_escaped $invalid_target_escaped
LINK $valid_link_escaped $file_escaped
-DIR
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ); }, "/ ^ \QDuplicate entry for $file at line 6 in file $dcmp_file\E \$ /xsm", '_load_dcmp_file() throws an exception if there are multiple files with the same name in the same directory' );

        #
        note('invalid dir entry');

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
DIR $dir_escaped invalid
-DIR
-DIR
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ); }, "/ ^ \QIncorrect number of arguments for DIR entry at line 2 in file $dcmp_file\E \$ /xsm", '_load_dcmp_file() throws an exception if there is a DIR entry with invalid arguments' );

        #
        $test->touch( $dcmp_file, <<'RECORD_FILE');
dcmp v1
DIR
-DIR
-DIR
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ); }, "/ ^ \QIncorrect number of arguments at line 2 in file $dcmp_file\E \$ /xsm", '_load_dcmp_file() throws an exception if there is a DIR entry with no arguments' );

        #
        note('invalid file entry');

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e invalid
-DIR
-DIR
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ); }, "/ ^ \QIncorrect number of arguments for FILE entry at line 3 in file $dcmp_file\E \$ /xsm", '_load_dcmp_file() throws an exception if there is a FILE entry with to many arguments' );

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
DIR $dir_escaped
FILE $file2_escaped 0
-DIR
-DIR
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ); }, "/ ^ \QIncorrect number of arguments for FILE entry at line 3 in file $dcmp_file\E \$ /xsm", '_load_dcmp_file() throws an exception if there is a FILE entry with to few arguments' );

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
DIR $dir_escaped
FILE $file2_escaped
-DIR
-DIR
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ); }, "/ ^ \QIncorrect number of arguments for FILE entry at line 3 in file $dcmp_file\E \$ /xsm", '_load_dcmp_file() throws an exception if there is a FILE entry with to few arguments' );

        #
        note('invalid link entry');

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
LINK $valid_link_escaped $file_escaped invalid
-DIR
-DIR
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ); }, "/ ^ \QIncorrect number of arguments for LINK entry at line 4 in file $dcmp_file\E \$ /xsm", '_load_dcmp_file() throws an exception if there is a LINK entry with to many arguments' );

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
LINK $valid_link_escaped
-DIR
-DIR
RECORD_FILE

        like( exception { App::DCMP::_load_dcmp_file( $dcmp_file, $ignore ); }, "/ ^ \QIncorrect number of arguments for LINK entry at line 4 in file $dcmp_file\E \$ /xsm", '_load_dcmp_file() throws an exception if there is a LINK entry with to few arguments' );

        #
        note('load valid dcmp file');

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
LINK $invalid_link_escaped $invalid_target_escaped
DIR $dir_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
LINK $valid_link_escaped $file_escaped
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
-DIR
RECORD_FILE

        for my $state ( 0 .. 3 ) {
            my @ignore =
                $state == 0 ? ()
              : $state == 1 ? ($file)
              : $state == 2 ? ( $file, $dir )
              : $state == 3 ? ( $file, $dir, $valid_link )
              :               BAIL_OUT 'internal error';

            if ( !@ignore ) {
                note(q{### @ignore = ()});
            }
            else {
                note( encode( 'UTF-8', q{### @ignore = ('} . join( q{', '}, @ignore ) . q{')} ) );
            }

            $ignore = App::DCMP::_ignored( [], \@ignore );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            my $iterator_dir_record = App::DCMP::_load_dcmp_file( $dcmp_file, $ignore );
            is( ref $iterator_dir_record, ref sub { }, '_load_records() returns a sub' );

            my @dirs = qw(no_such_dir);
            my $it   = $iterator_dir_record->( \@dirs );
            is( ref $it, ref sub { }, '... the returned sub returns a sub' );
            my $x_ref = $it->();
            is( $x_ref, undef, '... which returns undef for a non-existing path' );

            #
            note( encode( 'UTF-8', "check '$dir_text'" ) );
            @dirs = ($dir);
            $it   = $iterator_dir_record->( \@dirs );
            is( ref $it, ref sub { }, '... the returned sub returns a sub' );

            if ( $state < 2 ) {
                $x_ref = $it->();
                is( ref $x_ref, ref [], '... the sub returned from the sub returns an array ref' );
                is( scalar @{$x_ref}, 4,                                  '... with 4 elements' );
                is( ${$x_ref}[0],     $file2,                             '... correct name' );
                is( ${$x_ref}[1],     App::DCMP::FILE_TYPE_REGULAR(),     '... correct mode' );
                is( ${$x_ref}[2],     0,                                  '... correct size' );
                is( ${$x_ref}[3],     'd41d8cd98f00b204e9800998ecf8427e', '... correct md5' );
            }

            is( $it->(), undef, '... calling it again returns undef' );

            #
            note(q{check '.'});
            @dirs = qw();
            $it   = $iterator_dir_record->( \@dirs );
            is( ref $it, ref sub { }, '... the returned sub returns a sub' );

            if ( $state < 2 ) {
                $x_ref = $it->();
                is( ref $x_ref, ref [], '... the sub returned from the sub returns an array ref' );
                is( scalar @{$x_ref}, 2,                                '... with 2 elements' );
                is( ${$x_ref}[0],     $dir,                             '... correct name' );
                is( ${$x_ref}[1],     App::DCMP::FILE_TYPE_DIRECTORY(), '... correct mode' );
            }

            if ( $state == 0 ) {
                $x_ref = $it->();
                is( ref $x_ref, ref [], '... calling it again returns an array ref' );
                is( scalar @{$x_ref}, 4,                                  '... with 4 elements' );
                is( ${$x_ref}[0],     $file,                              '... correct name' );
                is( ${$x_ref}[1],     App::DCMP::FILE_TYPE_REGULAR(),     '... correct mode' );
                is( ${$x_ref}[2],     12,                                 '... correct size' );
                is( ${$x_ref}[3],     '6f5902ac237024bdd0c176cb93063dc4', '... correct md5' );
            }

            $x_ref = $it->();
            is( ref $x_ref, ref [], '... calling it again returns an array ref' );
            is( scalar @{$x_ref}, 3,                              '... with 3 elements' );
            is( ${$x_ref}[0],     $invalid_link,                  '... correct name' );
            is( ${$x_ref}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... correct mode' );
            is( ${$x_ref}[2],     $invalid_target,                '... correct target' );

            if ( $state < 3 ) {
                $x_ref = $it->();
                is( ref $x_ref, ref [], '... calling it again returns an array ref' );
                is( scalar @{$x_ref}, 3,                              '... with 3 elements' );
                is( ${$x_ref}[0],     $valid_link,                    '... correct name' );
                is( ${$x_ref}[1],     App::DCMP::FILE_TYPE_SYMLINK(), '... correct mode' );
                is( ${$x_ref}[2],     $file,                          '... correct target' );
            }

            is( $it->(), undef, '... calling it again returns undef' );
        }

        #
        note('escaped chars');

        my $dir3          = "dir >\t<> <> <>\n<>%<>${suffix_bin}";
        my $dir3_escaped  = App::DCMP::_escape_filename($dir3);
        my $file3         = "file >\t<> <> <>\n<>%<>${suffix_bin}.txt";
        my $file3_escaped = App::DCMP::_escape_filename($file3);

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
DIR $dir3_escaped
FILE $file3_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
-DIR
RECORD_FILE

        my @ignore;

        $ignore = App::DCMP::_ignored( [], \@ignore );
        is( ref $ignore, ref sub { }, '_ignore returns a sub' );

        my $iterator_dir_record = App::DCMP::_load_dcmp_file( $dcmp_file, $ignore );

        is( ref $iterator_dir_record, ref sub { }, '_load_records() returns a sub' );

        my @dirs = ($dir3);
        my $it   = $iterator_dir_record->( \@dirs );
        is( ref $it, ref sub { }, '... the returned sub returns a sub' );
        my $x_ref = $it->();

        is( ref $x_ref, ref [], '... the sub returned from the sub returns an array ref' );
        is( scalar @{$x_ref}, 4,                                  '... with 4 elements' );
        is( ${$x_ref}[0],     $file3,                             '... correct name' );
        is( ${$x_ref}[1],     App::DCMP::FILE_TYPE_REGULAR(),     '... correct mode' );
        is( ${$x_ref}[2],     0,                                  '... correct size' );
        is( ${$x_ref}[3],     'd41d8cd98f00b204e9800998ecf8427e', '... correct md5' );

        is( $it->(), undef, '... calling it again returns undef' );

        my %line_to_ignore = (
            'empty line'                              => q{},
            'line with tab'                           => "\t",
            'line with whitespaces'                   => q{   },
            'line with comment sign'                  => q{#},
            'line with comment sign after whitespace' => q{ #},
            'line with comment'                       => encode( 'UTF-8', "# comment$suffix_text" ),
        );

        for my $line_msg ( keys %line_to_ignore ) {
            note( encode( 'UTF-8', "ignore $line_msg at top" ) );

            $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
$line_to_ignore{$line_msg}
DIR $dir3_escaped
FILE $file3_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
-DIR
RECORD_FILE

            @ignore = ();

            $ignore = App::DCMP::_ignored( [], \@ignore );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            $iterator_dir_record = App::DCMP::_load_dcmp_file( $dcmp_file, $ignore );

            is( ref $iterator_dir_record, ref sub { }, '_load_records() returns a sub' );

            @dirs = ($dir3);
            $it   = $iterator_dir_record->( \@dirs );
            is( ref $it, ref sub { }, '... the returned sub returns a sub' );
            $x_ref = $it->();

            is( ref $x_ref, ref [], '... the sub returned from the sub returns an array ref' );
            is( scalar @{$x_ref}, 4,                                  '... with 4 elements' );
            is( ${$x_ref}[0],     $file3,                             '... correct name' );
            is( ${$x_ref}[1],     App::DCMP::FILE_TYPE_REGULAR(),     '... correct mode' );
            is( ${$x_ref}[2],     0,                                  '... correct size' );
            is( ${$x_ref}[3],     'd41d8cd98f00b204e9800998ecf8427e', '... correct md5' );

            is( $it->(), undef, '... calling it again returns undef' );
        }

        #
        note('with ignore path');

        my $dir4         = "dir4${suffix_bin}";
        my $dir4_text    = "dir4${suffix_text}";
        my $dir4_escaped = App::DCMP::_escape_filename($dir4);
        my $dir5         = "dir5${suffix_bin}";
        my $dir5_text    = "dir5${suffix_text}";
        my $dir5_escaped = App::DCMP::_escape_filename($dir5);

        $test->touch( $dcmp_file, <<"RECORD_FILE");
dcmp v1
LINK $invalid_link_escaped $invalid_target_escaped
DIR $dir_escaped
LINK $valid_link_escaped $file_escaped
DIR $dir4_escaped
FILE $file_escaped 12 6f5902ac237024bdd0c176cb93063dc4
DIR $dir5_escaped
FILE $file2_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
-DIR
-DIR
-DIR
RECORD_FILE

        for my $state ( 0 .. 5 ) {
            @ignore =
                $state == 0 ? ()
              : $state == 1 ? ('no_such_dir')
              : $state == 2 ? ( File::Spec->canonpath( File::Spec->catdir($dir) ) )
              : $state == 3 ? ( File::Spec->canonpath( File::Spec->catdir( $dir, $dir4 ) ) )
              : $state == 4 ? ( File::Spec->canonpath( File::Spec->catdir( $dir, $dir4, $dir5 ) ) )
              : $state == 5 ? ( 'no_such_dir', File::Spec->canonpath( File::Spec->catdir( $dir, $dir4, $dir5 ) ) )
              :               BAIL_OUT 'internal error';

            if ( !@ignore ) {
                note(q{### @ignore = ()});
            }
            else {
                note( encode( 'UTF-8', q{### @ignore = ('} . join( q{', '}, @ignore ) . q{')} ) );
            }

            $ignore = App::DCMP::_ignored( \@ignore, [] );
            is( ref $ignore, ref sub { }, '_ignore returns a sub' );

            $iterator_dir_record = App::DCMP::_load_dcmp_file( $dcmp_file, $ignore );
            is( ref $iterator_dir_record, ref sub { }, '_load_records() returns a sub' );

            @dirs = qw(no_such_dir);
            $it   = $iterator_dir_record->( \@dirs );
            is( ref $it, ref sub { }, '... the returned sub returns a sub' );
            $x_ref = $it->();
            is( $x_ref, undef, '... which returns undef for a non-existing path' );

            #
            note( encode( 'UTF-8', "check '$dir_text/$dir4_text/$dir5_text'" ) );
            @dirs = ( $dir, $dir4, $dir5 );
            $it = $iterator_dir_record->( \@dirs );
            is( ref $it, ref sub { }, '... the returned sub returns a sub' );

            if ( $state < 2 ) {
                $x_ref = $it->();
                is( ref $x_ref, ref [], '... the sub returned from the sub returns an array ref' );
                is( scalar @{$x_ref}, 4,                                  '... with 4 elements' );
                is( ${$x_ref}[0],     $file2,                             '... correct name' );
                is( ${$x_ref}[1],     App::DCMP::FILE_TYPE_REGULAR(),     '... correct mode' );
                is( ${$x_ref}[2],     0,                                  '... correct size' );
                is( ${$x_ref}[3],     'd41d8cd98f00b204e9800998ecf8427e', '... correct md5' );
            }

            is( $it->(), undef, '... calling it again returns undef' );
        }
    }

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
