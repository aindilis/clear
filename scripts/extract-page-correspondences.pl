#!/usr/bin/perl -w

use Clear::Util::PageCounter;

use BOSS::Config;
use PerlLib::SwissArmyKnife;
use Rival::Lingua::EN::Sentence qw (get_sentences);

$specification = q(
	-f <file>		File to process
	-t <text>		Text to process
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
# $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/system";

my $verbose = 0;

my $text;
my $filename;
if ($conf->{'-f'}) {
  $filename = $conf->{'-f'};
  if (-f $filename) {
    $text = read_file($filename);
  }
} elsif ($conf->{'-t'}) {
  $text = $conf->{'-t'};
}

if ($text) {
  my $sentences = get_sentences($text);
  my $pagecounter = Clear::Util::PageCounter->new
    (
     Contents => $sentences,
    );
  $pagecounter->ComputePageNumbers();
  print Dumper({PageNos => $pagecounter->PageNos}) if $verbose;
  print '(list '.join(' ',@{$pagecounter->PageNos}).')'."\n";
}
