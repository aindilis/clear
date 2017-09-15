#!/usr/bin/perl -w

# a system to determine areas of non-sentences

# could use Learner::Method here when it works.

# for now use Lingua::LinkParser;

use Clear::DocData;

use Data::Dumper;
use System::LinkParser;

my $p = System::LinkParser->new;

my $f = $ARGV[0];
my $c = `zcat "$f"`;
my $e = eval $c;

my $estimate = {};

foreach my $l (@{$e->{Contents}}) {
  if ($p->CheckSentence(Sentence => $l)) {
    # $estimate->{$l} = "sentence";
    print "1 ";
  } else {
    $estimate->{$l} = "unknown";
    print "0 ";
  }
  print "$l\n";
}
