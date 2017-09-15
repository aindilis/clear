#!/usr/bin/perl -w

use BOSS::Config;
use PerlLib::SwissArmyKnife;
use PerlLib::ToText;
use Lingua::EN::Sentence qw (get_sentences);
use Rival::Lingua::EN::Sentence qw (rival_get_sentences);

use Error qw(:try);

$specification = q(
	-f <file>		File to read
	-o			Overwrite results
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;

my $data1 = 'data/data1.txt';
my $data2 = 'data/data2.txt';
my $generate = 0;
if ((! -f $data1 and ! -f $data2) or $conf->{'-o'}) {
  $generate = 1;
}

if ($generate) {
  my $totext = PerlLib::ToText->new();
  my $filename = $conf->{'-f'} || die "no file specified\n";

  my $datadoc;
  my @sentences;
  my $c;
  my $res = $totext->ToText
    (
     File => $filename,
     # Type => $type,
     UseBodyTextExtractor => 0,
     Unidecode => 1,
     CleanStrangeCharacters => 1,
     Raw => 1,
    );

  my $skip = 0;
  my $skiprival = 0;

  if ($res->{Success}) {
    $res->{Text} =~ s/’/'/sg;
    $c = $res->{Text};


    try {
      my $sentences = get_sentences($c);
      @sentences = FilterSentences(@$sentences);
    }
      catch Error with {
	$skip = 1;
	print STDERR "Error: can't get and filter sentences.\n";
	print STDERR Dumper(@_);
      };

    try {
      my $rivalsentences = rival_get_sentences($c);
      @rivalsentences = FilterSentences(@$rivalsentences);
    }
      catch Error with {
	# $skiprival = 1;
	print STDERR "Error: can't rival get and filter sentences.\n";
	print STDERR Dumper(@_);
      };
  }

  # THIS IS THE FILE THAT CONTAINS THE ORIGINAL CONTENTS OF THE ToText CONVERSION
  $fh = IO::File->new;
  $fh->open(">data/c.txt") or die "Owie!\n";
  print $fh $c;
  $fh->close();


  if (! $skip) {
    # THIS IS THE FILE THAT CONTAINS THE DUMP OF THE SENTENCES PARSED WITH THE REGULAR Lingua::EN::Sentence
    my $fh = IO::File->new;
    $fh->open(">data/sentences.txt") or die "Owie!\n";
    print $fh Dumper(\@sentences);
    $fh->close();

  }
  if (! $skiprival) {
    # THIS IS THE FILE THAT CONTAINS THE DUMP OF THE SENTENCES PARSED WITH THE RIVAL Rival::Lingua::EN::Sentence
    $fh = IO::File->new;
    $fh->open(">data/rivalsentences.txt") or die "Owie!\n";
    print $fh Dumper(\@rivalsentences);
    $fh->close();

    my $data1txt = $c;

    $data1txt =~ s//DFJKLSFJDK-CLEAR-SUBSTITUTE-DFJKLSFJDK/sg;
    $data1txt =~ s/[\s\n\r]+//sg;
    $data1txt =~ s/DFJKLSFJDK-CLEAR-SUBSTITUTE-DFJKLSFJDK//sg;

    # THIS IS THE REGULAR SENTENCES JOINED TOGETHER AND STRIPPED OF WHITESPACE
    $fh = IO::File->new;
    $fh->open(">$data1") or die "Owie!\n";
    print $fh $data1txt;
    $fh->close();


    my $data2txt = join(" ",@rivalsentences);

    # THIS IS THE FILE THAT CONTAINS THE RIVAL SENTENCES JOINED TOGETHER
    $fh = IO::File->new;
    $fh->open(">data/d.txt") or die "Owie!\n";
    print $fh $data2txt;
    $fh->close();

    $data2txt =~ s//DFJKLSFJDK-CLEAR-SUBSTITUTE-DFJKLSFJDK/sg;
    $data2txt =~ s/[\s\n\r]+//sg;
    $data2txt =~ s/DFJKLSFJDK-CLEAR-SUBSTITUTE-DFJKLSFJDK//sg;

    # THIS IS THE RIVAL SENTENCES JOINED TOGETHER AND STRIPPED OF WHITESPACE
    $fh = IO::File->new;
    $fh->open(">$data2") or die "Owie!\n";
    print $fh $data2txt;
    $fh->close();

  }
}

my @c1 = split //, read_file('data/data1.txt');
my @c2 = split //, read_file('data/data2.txt');

my $size = 15;

my @c1hist;
my @c2hist;
while (scalar @c1 and scalar @c2) {
  my $char1 = shift @c1;
  my $char2 = shift @c2;
  if ($char1 eq $char2) {
    print STDERR $char1;
  } else {
    if ($char1 =~ /(\.|\')/) {
      while ($char1 eq $1) {
	print STDERR "$char1/$1\n";
	$char1 = shift @c1;
      }
      print STDERR "\n";
    } else {
      print STDERR "\n\n\n";
      print STDERR Dumper({C1 => $char1});
      print STDERR Dumper({C2 => $char2});
      print STDERR "\n";
      print STDERR Dumper({C1Cont => join("",reverse (@c1hist[0..($size - 1)])). "  " .join("",@c1[0..($size - 1)])});
      print STDERR Dumper({C2Cont => join("",reverse (@c2hist[0..($size - 1)])). "  " .join("",@c2[0..($size - 1)])});
      die "ARGGH!\n";
    }
  }
  unshift @c1hist, $char1;
  unshift @c2hist, $char2;
}

sub FilterSentences {
  my (@sentences) = @_;
  # now let us be sure to clean up any nonsense via POS tagging
  # Add part of speech tags to a text
  foreach my $sentence (@sentences) {
    # print "<$sentence>\n";

    $sentence =~ s/(.)\1{4,}/ /g;
    $sentence =~ s/ \W / /g;
    $sentence =~ s/\|/ /g;
    $sentence =~ s// CLEAR-COMMAND-CONTROL-L-CLEAR-COMMAND /sg;
    $sentence =~ s/[\n\s]+/ /g;
    $sentence =~ s/ ?CLEAR-COMMAND-CONTROL-L-CLEAR-COMMAND ?//sg;

    # print "<$sentence>\n";
    # my $tagged_text = $UNIVERSAL::clear->Tagger->add_tags( $sentence );
    # print Dumper($tagged_text);
  }
  # # Get a list of all nouns and noun phrases with occurrence counts
  # my %word_list = $p->get_words( $text );
  # # Get a readable version of the tagged text
  # my $readable_text = $p->get_readable( $text );
  return @sentences;
}
