#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::Fatal;
use Test::More 0.88;
use Test::TempDir::Tiny;

use Encode;
use File::Spec;

use lib qw(.);

main();

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    my @suffixes = ( q{}, "_\x{20ac}", "_\x{00C0}", "_\x{0041}\x{0300}" );

    for my $suffix (@suffixes) {
        note(q{----------------------------------------------------------});
        note( encode( 'UTF-8', "suffix: $suffix" ) );

        my $file = "file${suffix}.txt";

        my $nonexisting_file = File::Spec->catfile( tempdir(), $file );

        like( exception { App::DCMP::_load_dcmp_file($nonexisting_file) }, encode( 'UTF-8', "/ ^ \QCannot read file $nonexisting_file: \E /xsm" ), '_load_dcmp_file throws an exception if the dcmp file cannot be read' );

        my $dcmp_file = File::Spec->catfile( tempdir(), "file${suffix}.dcmp" );
        my $dcmp_file_utf8 = encode( 'UTF-8', $dcmp_file );

        my $dir            = "dir${suffix}";
        my $file2          = "file2${suffix}.txt";
        my $invalid_link   = "invalid_link${suffix}.txt";
        my $invalid_target = "invalid_target${suffix}.txt";
        my $valid_link     = "valid_link${suffix}.txt";

        #
        note('invalid enty in dcmp file');

        open my $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<'RECORD_FILE';
INVALID entry
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file) }, encode( 'UTF-8', "/ ^ \QInvalid entry on line 1 in file $dcmp_file\E \$ /xsm" ), '_load_dcmp_file() throws an exception if the dcmp file contains an invalid entry' );

        #
        note('to many -DIR in dcmp file');

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
DIR $dir
FILE $file2 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
FILE $file 12 6f5902ac237024bdd0c176cb93063dc4
-DIR
LINK $invalid_link $invalid_target
LINK $valid_link $file
-DIR
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, encode( 'UTF-8', "/ ^ \QUnbalanced -DIR on line 5 in file $dcmp_file\E \$ /xsm" ), q{_load_dcmp_file() throws an exception if there are to many '-DIR'} );

        #
        note('missing -DIR at end in dcmp file');

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
DIR $dir
FILE $file2 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
FILE $file 12 6f5902ac237024bdd0c176cb93063dc4
LINK $invalid_link $invalid_target
LINK $valid_link $file
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, encode( 'UTF-8', "/ ^ \QUnbalanced -DIR at end of file $dcmp_file\E \$ /xsm" ), q{_load_dcmp_file() throws an exception if there are to few '-DIR'} );

        #
        note('duplicate file in directory');

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
DIR $dir
FILE $file2 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
FILE $file 12 6f5902ac237024bdd0c176cb93063dc4
FILE $file 12 6f5902ac237024bdd0c176cb93063dc4
LINK $invalid_link $invalid_target
LINK $valid_link $file
-DIR
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, encode( 'UTF-8', "/ ^ \QDuplicate entry for $file at line 5 in file $dcmp_file\E \$ /xsm" ), '_load_dcmp_file() throws an exception if there are multiple files with the same name in the same directory' );

        #
        note('invalid dir entry');

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
DIR $dir invalid
-DIR
-DIR
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, encode( 'UTF-8', "/ ^ \QIncorrect number of arguments for DIR entry at line 1 in file $dcmp_file\E \$ /xsm" ), '_load_dcmp_file() throws an exception if there is a DIR entry with invalid arguments' );

        #
        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<'RECORD_FILE';
DIR
-DIR
-DIR
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, encode( 'UTF-8', "/ ^ \QIncorrect number of arguments at line 1 in file $dcmp_file\E \$ /xsm" ), '_load_dcmp_file() throws an exception if there is a DIR entry with no arguments' );

        #
        note('invalid file entry');

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
DIR $dir
FILE $file2 0 d41d8cd98f00b204e9800998ecf8427e invalid
-DIR
-DIR
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, encode( 'UTF-8', "/ ^ \QIncorrect number of arguments for FILE entry at line 2 in file $dcmp_file\E \$ /xsm" ), '_load_dcmp_file() throws an exception if there is a FILE entry with to many arguments' );

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
DIR $dir
FILE $file2 0
-DIR
-DIR
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, encode( 'UTF-8', "/ ^ \QIncorrect number of arguments for FILE entry at line 2 in file $dcmp_file\E \$ /xsm" ), '_load_dcmp_file() throws an exception if there is a FILE entry with to few arguments' );

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
DIR $dir
FILE $file2
-DIR
-DIR
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, encode( 'UTF-8', "/ ^ \QIncorrect number of arguments for FILE entry at line 2 in file $dcmp_file\E \$ /xsm" ), '_load_dcmp_file() throws an exception if there is a FILE entry with to few arguments' );

        #
        note('invalid link entry');

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
DIR $dir
FILE $file2 0 d41d8cd98f00b204e9800998ecf8427e
LINK $valid_link $file invalid
-DIR
-DIR
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, encode( 'UTF-8', "/ ^ \QIncorrect number of arguments for LINK entry at line 3 in file $dcmp_file\E \$ /xsm" ), '_load_dcmp_file() throws an exception if there is a LINK entry with to many arguments' );

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
DIR $dir
FILE $file2 0 d41d8cd98f00b204e9800998ecf8427e
LINK $valid_link
-DIR
-DIR
RECORD_FILE
        close $fh;

        like( exception { App::DCMP::_load_dcmp_file($dcmp_file); }, encode( 'UTF-8', "/ ^ \QIncorrect number of arguments for LINK entry at line 3 in file $dcmp_file\E \$ /xsm" ), '_load_dcmp_file() throws an exception if there is a LINK entry with to few arguments' );

        #
        note('load valid dcmp file');

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
LINK $invalid_link $invalid_target
DIR $dir
FILE $file2 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
LINK $valid_link $file
FILE $file 12 6f5902ac237024bdd0c176cb93063dc4
-DIR
RECORD_FILE
        close $fh;

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

            my $iterator_dir_record = App::DCMP::_load_dcmp_file( $dcmp_file, \@ignore );
            is( ref $iterator_dir_record, ref sub { }, '_load_records() returns a sub' );

            my @dirs = qw(no_such_dir);
            my $it   = $iterator_dir_record->( \@dirs );
            is( ref $it, ref sub { }, '... the returned sub returns a sub' );
            my $x_ref = $it->();
            is( $it->(), undef, '... which returns undef for a non-existing path' );

            #
            note( encode( 'UTF-8', "check '$dir'" ) );
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

        my $file3         = "file >\t<> <> <>\n<>%<>${suffix}.txt";
        my $file3_escaped = "file%20>%09<>%20<>%20<>%0A<>%25<>${suffix}.txt";

        my $dir3         = "dir >\t<> <> <>\n<>%<>${suffix}";
        my $dir3_escaped = "dir%20>%09<>%20<>%20<>%0A<>%25<>${suffix}";

        is( App::DCMP::_escape_filename($file3), $file3_escaped, encode( 'UTF-8', "$file3_escaped - gets correctly escaped" ) );
        is( App::DCMP::_unescape_filename($file3_escaped), $file3, '... and unescaped' );

        is( App::DCMP::_escape_filename($dir3), $dir3_escaped, encode( 'UTF-8', "$dir3_escaped - gets correctly escaped" ) );
        is( App::DCMP::_unescape_filename($dir3_escaped), $dir3, '... and unescaped' );

        open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
        print {$fh} <<"RECORD_FILE";
DIR $dir3_escaped
FILE $file3_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
-DIR
RECORD_FILE
        close $fh;

        my @ignore;
        my $iterator_dir_record = App::DCMP::_load_dcmp_file( $dcmp_file, \@ignore );

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
            'line with comment'                       => "# comment$suffix",
        );

        for my $line_msg ( keys %line_to_ignore ) {
            note( encode( 'UTF-8', "ignore $line_msg at top" ) );

            open $fh, '>:encoding(UTF-8)', $dcmp_file_utf8;
            print {$fh} <<"RECORD_FILE";
$line_to_ignore{$line_msg}
DIR $dir3_escaped
FILE $file3_escaped 0 d41d8cd98f00b204e9800998ecf8427e
-DIR
-DIR
RECORD_FILE
            close $fh;

            @ignore = ();
            $iterator_dir_record = App::DCMP::_load_dcmp_file( $dcmp_file, \@ignore );

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
    }
    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
