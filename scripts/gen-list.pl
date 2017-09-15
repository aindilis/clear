#!/usr/bin/perl -w

use Data::Dumper;

if (! @ARGV) {
  print "Usage: gen-list.pl <directory>\n";
  print "List all pdf files\n";
} elsif (-d $ARGV[0]) {
  # system "find \"$ARGV[0]\" | grep -iE '\\.(pdf|htm|html|txt)\$'";
  # replace with a file based alternative
  system "find \"$ARGV[0]\" | grep -iE '\\.(pdf|htm|html|txt)\$'";
} else {
  print "Directory not found.\n";
}
