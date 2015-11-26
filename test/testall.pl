#!/usr/bin/perl -w

use strict;
use Test::Harness;

$Test::Harness::verbose = 1;

my $pat = $ARGV[0] || '';
my @testfiles = sort glob($pat.'*.t');
runtests(@testfiles);
