#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;
use PerlLib::ToText;

use Lingua::EN::Sentence qw(get_sentences);

my $c = read_file('06IJAIED.txt');

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



sub rival_get_sentences {
  my ($text) = shift;
  my $sent = get_sentences($text);
  my $verbose = 0;
  my @alltokens = split /[^A-Za-z0-9]+/, $text;
  my $quit = 0;
  my $sent2;
  my @tokens;
  my @context;
  my @sentencesresult = ();
  while (! $quit) {
    while (@$sent) {
      my $innerquit = 0;
      while (! $innerquit) {
	if (! scalar @$sent) {
	  $innerquit = 1;
	}
	next if $innerquit;
	if (! scalar @tokens) {
	  push @sentencesresult, join('',@output);
	  @output = ();
	  $sent2 = shift @$sent;
	  print Dumper($sent2) if $verbose;
	  @tokens = ();
	  @context = ();
	  my @items = $sent2 =~ /(.*?)([A-Za-z0-9]+)(.*?)/sg;
	  $items[-1] = substr($sent2,length(join('',@items)));
	  my $i = 0;
	  while (@items) {
	    my $pre = shift @items;
	    my $token = shift @items;
	    my $post = shift @items;
	    # print "<$token>\n" if $verbose;
	    push @tokens, $token;
	    $context[$i++] = [$pre,$token,$post];
	  }
	}
	my $alltoken;
	if ($alltokens[0] eq $tokens[0]) {
	  # print "ho\n" if $verbose;
	  my $alltoken = shift @alltokens;
	  shift @tokens;
	  my $context = shift @context;
	  my $added = join("", @$context);
	  print "<$added>\n" if $verbose;
	  push @output, $added;
	} else {
	  print "hi\n" if $verbose;
	  my @res;
	  if ($alltokens[0] eq '') {
	    shift @alltokens;
	  } elsif ($alltokens[0] eq '') {
	    shift @alltokens;
	    print Dumper({Context => \@context}) if $verbose;
	    $context[0][0] = $context[0][0].'';
	  } elsif ($alltokens[0] =~ //) {
	    @res = $alltokens[0] =~ /^([^]*?)()([^]*?)$/s;
	    # '^LTable' -> ['','','Table']
	    print Dumper({Res => \@res}) if $verbose;
	    shift @alltokens;
	    unshift @alltokens, @res;
	  } else {
	    print Dumper
	      ({
		Token => [$tokens[0]],
		AllToken => [$alltokens[0]],
		Tokens => \@tokens,
		AllTokens => [splice(@alltokens,0,5)],
		# Context => [$context[0]],
		AllContext => [splice(@context,0,2)],
	       });
	    # try to align
	    # just die for now
	    die "Cannot\n";
	  }
	}
      }
    }
    if (! scalar @alltokens) {
      $quit = 1;
    } elsif ($alltokens[0] eq '') {
      $sentencesresult[-1] = $sentencesresult[-1].'';
      $quit = 1;
    } else {
      print Dumper({AllTokens => \@alltokens});
      die "Not aligned\n";
    }
  }
  return \@sentencesresult;
}

sub FilterSentences {
  my ($self,@sentences) = @_;
  # now let us be sure to clean up any nonsense via POS tagging
  # Add part of speech tags to a text
  foreach my $sentence (@sentences) {
    $sentence =~ s/(.)\1{4,}/ /g;
    $sentence =~ s/ \W / /g;
    $sentence =~ s/\|/ /g;
    $sentence =~ s/[\n\s]+/ /g;

    # my $tagged_text = $UNIVERSAL::clear->Tagger->add_tags( $sentence );
    # print Dumper($tagged_text);
  }
  # # Get a list of all nouns and noun phrases with occurrence counts
  # my %word_list = $p->get_words( $text );
  # # Get a readable version of the tagged text
  # my $readable_text = $p->get_readable( $text );
  return @sentences;
}


