#!/usr/bin/perl -w

use Data::Dumper;

my @res = (a..z);

while (@res) {
  my $i = int(rand(@res));
  print Dumper(\@res);
  print RemoveIthElementFromList($i,\@res)."\n";
}

sub RemoveIthElementFromList {
  my ($i,$list) = @_;

  if ($i >= 0 and $i <= $#$list) {
    my $ret = $list->[$i];
    my @res;
    foreach my $j (0..$#$list) {
      if ($j > $i) {
	$list->[$j-1] = $list->[$j];
      }
    }
    delete $list->[$#$list];
    return $ret;
  }
}
