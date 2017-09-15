#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;
use PerlLib::ToText;
use Rival::Lingua::EN::Sentence qw(get_sentences);

my $totext = PerlLib::ToText->new();

my $res = $totext->ToText
  (
   File => '06IJAIED.pdf',
   # Type => $type,
   # UseBodyTextExtractor => (defined $UNIVERSAL::clear and exists $UNIVERSAL::clear->Config->CLIConfig->{'--body'}),
   Unidecode => 1,
   CleanStrangeCharacters => 1,
   GetPageBreaksIfPossible => 1,
  );

print Dumper(get_sentences($res->{Text}));
