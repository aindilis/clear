#!/usr/bin/perl -w

use Data::Dumper;

my @a = 1..100;

print Dumper(@a[5..10])."\n";
