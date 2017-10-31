#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.031

use Test::More;

use lib qw(.);

my @modules = qw(
  bin/dcmp
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
