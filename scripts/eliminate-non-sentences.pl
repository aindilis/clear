#!/usr/bin/perl -w

# also use technique for scrubbing text I developed at CMU.

# a system to determine areas of non-sentences

# could use Learner::Method here when it works.

# for now use Lingua::LinkParser;

use Org::FRDCSA::Clear::DocData;

use Data::Dumper;
use Lingua::LinkParser;

my $p = Lingua::LinkParser->new;

my $f = $ARGV[0];
my $c = `zcat "$f"`;
my $e = eval $c;

my $estimate = {};

foreach my $l (@{$e->Contents}) {
  my @tokens = split /\W+/, $l;
  if (scalar @tokens < 20) {
    my $ls = $p->create_sentence($l);
    my @li = $ls->linkages;
    if (scalar @li) {
      $estimate->{$l} = "sentence";
    } else {
      $estimate->{$l} = "not sentence";
    }
  } else {
    $estimate->{$l} = "unknown";
  }
}

foreach my $l (@{$e->Contents}) {
  print "$l\n";
  print "\t".$estimate->{$l}."\n\n";
}
