#!/usr/bin/perl -w

use PerlLib::BodyTextExtractor;

use Data::Dumper;

my $file = shift;
if (-f $file) {
  my $c = `cat "$file"`;
  print BodyTextExtractor(HTML => $c);
}
