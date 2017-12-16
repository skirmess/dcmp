#!perl

use 5.006;
use strict;
use warnings;
use autodie;

use Test::More 0.88;

use lib qw(.);

main();

my @test_func_args;
my $test_func_return;
my $test_func_called;

sub _test_func {
    @test_func_args = @_;

    $test_func_called = 1;

    return $test_func_return;
}

sub main {
    require_ok('bin/dcmp') or BAIL_OUT();

    #
    note('no arguments while currying');

    my $curried_test_func = App::DCMP::_curry( \&_test_func );
    is( ref $curried_test_func, ref sub { }, '_curry returns a function' );

    #
    note('no arguments while calling curried func');

    my $func = $curried_test_func->();
    is( ref $func, ref sub { }, '... which returns a function' );

    #
    note('no arguments while calling created function');

    $test_func_called = 0;
    $test_func_return = undef;

    is( $func->(),         undef, '... which returns undef' );
    is( $test_func_called, 1,     '... and did call our test function' );
    is_deeply( \@test_func_args, [], '... without arguments' );

    #
    note('with arguments while calling created function');

    $test_func_called = 0;
    $test_func_return = 'hello world';

    is( $func->(qw(x y z)), 'hello world', '... which returns the correct return value' );
    is( $test_func_called,  1,             '... and did call our test function' );
    is_deeply( \@test_func_args, [qw(x y z)], '... with the correct arguments' );

    #
    note('with arguments while calling curried func');

    $func = $curried_test_func->(qw(m n o));
    is( ref $func, ref sub { }, '... which returns a function' );

    #
    note('no arguments while calling created function');

    $test_func_called = 0;
    $test_func_return = undef;

    is( $func->(),         undef, '... which returns undef' );
    is( $test_func_called, 1,     '... and did call our test function' );
    is_deeply( \@test_func_args, [qw(m n o)], '... without arguments' );

    #
    note('with arguments while calling created function');

    $test_func_called = 0;
    $test_func_return = 'hello world';

    is( $func->(qw(x y z)), 'hello world', '... which returns the correct return value' );
    is( $test_func_called,  1,             '... and did call our test function' );
    is_deeply( \@test_func_args, [qw(m n o x y z)], '... with the correct arguments' );

    #
    note('with arguments while currying');

    $curried_test_func = App::DCMP::_curry( \&_test_func, qw(a b c) );
    is( ref $curried_test_func, ref sub { }, '_curry returns a function' );

    #
    note('no arguments while calling curried func');

    $func = $curried_test_func->();
    is( ref $func, ref sub { }, '... which returns a function' );

    #
    note('no arguments while calling created function');

    $test_func_called = 0;
    $test_func_return = undef;

    is( $func->(),         undef, '... which returns undef' );
    is( $test_func_called, 1,     '... and did call our test function' );
    is_deeply( \@test_func_args, [qw(a b c)], '... without arguments' );

    #
    note('with arguments while calling created function');

    $test_func_called = 0;
    $test_func_return = 'hello world';

    is( $func->(qw(x y z)), 'hello world', '... which returns the correct return value' );
    is( $test_func_called,  1,             '... and did call our test function' );
    is_deeply( \@test_func_args, [qw(a b c x y z)], '... with the correct arguments' );

    #
    note('with arguments while calling curried func');

    $func = $curried_test_func->(qw(m n o));
    is( ref $func, ref sub { }, '... which returns a function' );

    #
    note('no arguments while calling created function');

    $test_func_called = 0;
    $test_func_return = undef;

    is( $func->(),         undef, '... which returns undef' );
    is( $test_func_called, 1,     '... and did call our test function' );
    is_deeply( \@test_func_args, [qw(a b c m n o)], '... without arguments' );

    #
    note('with arguments while calling created function');

    $test_func_called = 0;
    $test_func_return = 'hello world';

    is( $func->(qw(x y z)), 'hello world', '... which returns the correct return value' );
    is( $test_func_called,  1,             '... and did call our test function' );
    is_deeply( \@test_func_args, [qw(a b c m n o x y z)], '... with the correct arguments' );

    #
    note('with arguments while currying');

    $curried_test_func = App::DCMP::_curry( \&_test_func, qw(a b c) );
    is( ref $curried_test_func, ref sub { }, '_curry returns a function' );

    #
    note('with arguments while calling curried func');

    $func = $curried_test_func->(qw(m n o));
    is( ref $func, ref sub { }, '... which returns a function' );

    #
    note('with different arguments while calling curried func');

    my $func2 = $curried_test_func->(qw(d e f));
    is( ref $func, ref sub { }, '... which returns a function' );

    #
    note('with arguments while calling created function');

    $test_func_called = 0;
    $test_func_return = 'hello world';

    is( $func->(qw(x y z)), 'hello world', '... which returns the correct return value' );
    is( $test_func_called,  1,             '... and did call our test function' );
    is_deeply( \@test_func_args, [qw(a b c m n o x y z)], '... with the correct arguments' );

    #
    note('with different arguments while calling created function');

    $test_func_called = 0;
    $test_func_return = 'hello world';

    is( $func2->(qw(g h i)), 'hello world', '... which returns the correct return value' );
    is( $test_func_called,   1,             '... and did call our test function' );
    is_deeply( \@test_func_args, [qw(a b c d e f g h i)], '... with the correct arguments' );

    #
    done_testing();

    exit 0;
}

# vim: ts=4 sts=4 sw=4 et: syntax=perl
