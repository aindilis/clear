#!/usr/bin/perl -w

use IM::Modules::GoogleImages;
use Manager::Dialog qw(Approve);

use Data::Dumper;
use Lingua::EN::Tagger;
use Lingua::EN::Sentence qw(get_sentences);

my $samplefile = "FINAL-NOTES";
my $text = `cat $samplefile`;
my $sentences = get_sentences($text);

my $p = Lingua::EN::Tagger->new(stem => 0);
my $gi = IM::Modules::GoogleImages->new();

foreach my $sentence (@$sentences) {
  $sentence =~ s/[\n\r]/ /g;
  $sentence =~ s/\s+/ /g;
  my $res = {$p->get_max_noun_phrases($p->add_tags($sentence))};
  foreach my $k (keys %$res) {
    if (Approve($k)) {
      $gi->Search(Search => $k);
    }
  }
}
