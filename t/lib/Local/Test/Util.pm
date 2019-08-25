package Local::Test::Util;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Test::Builder;

## no critic (Subroutines::ProhibitBuiltinHomonyms)

sub new {
    my ($class) = @_;

    my $self;
    $self->{_builder} = Test::Builder->new;

    bless $self, $class;
    return $self;
}

sub _builder {
    my ($self) = @_;

    return $self->{_builder};
}

sub chdir {
    my ( $self, $dir ) = @_;

    my $rc = CORE::chdir($dir);
    $self->_builder->BAIL_OUT("chdir $dir: $!") if !$rc;
    return $rc;
}

sub mkdir {
    my ( $self, $dir ) = @_;

    my $rc = CORE::mkdir $dir;
    $self->_builder->BAIL_OUT("mkdir $dir: $!") if !$rc;
    return $rc;
}

sub symlink {
    my ( $self, $old_name, $new_name ) = @_;

    my $rc = symlink $old_name, $new_name;
    $self->_builder->BAIL_OUT("symlink $old_name, $new_name: $!") if !$rc;
    return $rc;
}

sub touch {
    my ( $self, $file, @content ) = @_;

    if ( open my $fh, '>', $file ) {
        if ( print {$fh} @content ) {
            return if close $fh;
        }
    }

    $self->_builder->BAIL_OUT("Cannot write file '$file': $!");
    die;
}

sub touch_utf8 {
    my ( $self, $file, @content ) = @_;

    if ( open my $fh, '>:encoding(UTF-8)', $file ) {
        if ( print {$fh} @content ) {
            return if close $fh;
        }
    }

    $self->_builder->BAIL_OUT("Cannot write file '$file': $!");
    die;
}

1;

__END__

# vim: ts=4 sts=4 sw=4 et: syntax=perl
