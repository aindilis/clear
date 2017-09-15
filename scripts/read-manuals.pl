#!/usr/bin/perl -w

foreach my $file (split /\n/,`cat manuals | rl`) {
  system "acroread -geometry 1270x1000+0+0 \"$file\"";
}
