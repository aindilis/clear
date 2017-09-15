#!/usr/bin/perl -w

# /usr/share/info/gcal.info

# read an info page

use Manager::Dialog qw(Choose);

sub GetList {
  my $h = {};
  foreach my $f (split /\n/,`ls /usr/share/info`) {
    $f =~ s/[-\.].*//g;
    $h->{$f} = 1;
  }
  Choose(sort keys %$h);
}

sub GetFiles {
  my $name = shift;
  my @res;
  my $h = {};
  foreach my $f (split /\n/,`ls /usr/share/info/$name.*`) {
    if ($f =~ /^\/usr\/share\/info\/(.*)\.info-([0-9]+)\.gz$/) {
      $h->{$2} = 1;
    }
  }
  foreach my $i (sort {$a <=> $b} keys %$h) {
    push @res, "/usr/share/info/$name.info-$i.gz";
  }
  if (! @res) {
    push @res, "/usr/share/info/$name.info.gz";
  }
  return @res;
}

foreach my $f (GetFiles(GetList())) {
  print "Reading $f\n";
  system "zcat $f > /tmp/clear.txt";
  system "rm /tmp/clear.txt.voy";
  system "cla -f 'ASCII English text' -r /tmp/clear.txt";
}
