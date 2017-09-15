#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;

use Lingua::EN::Sentence qw(get_sentences);

my $text = "The Homunculus, Sir, in however low and ludicrous a light
he may appear, in this age of levity, to the eye of folly or
prejudice;--to the eye of reason in scientific research, he stands
confess'd--a Being guarded and circumscribed with rights.--The
minutest philosophers, who by the bye, have the most enlarged
understandings, (their souls being inversely as their enquiries) shew
us incontestably, that the Homunculus is created by the same
hand,--engender'd in the same course of nature,--endow'd with the same
loco-motive powers and faculties with us:--That he consists as we do,
of skin, hair, fat, flesh, veins, arteries, ligaments, nerves,
cartilages, bones, marrow, brains, glands, genitals, humours, and
articulations;--is a Being of as much activity,--and in all senses of
the word, as much and as truly our fellow-creature as my Lord
Chancellor of England.--He may be benefitted,--he may be injured,--he
may obtain redress; in a word, he has all the claims and rights of
humanity, which Tully, Puffendorf, or the best ethick writers allow to
arise out of that state and relation.";

print Dumper(IntelligentSplit(Text => $text, Size => 30, SplitRE => ";"));

sub IntelligentSplit {
  my %args = @_;
  my $text = $args{Text};
  $text =~ s/[\n\r]+/ /g;
  $text =~ s/\s+/ /g;
  if (length($text) > $args{Size}) {
    # badness
    my $sentences = get_sentences($text);
    my @chunks;

    my @sentences = @$sentences;
    while (@sentences) {
      my $sentence = shift @sentences;
      my @subchunks;
      if ($args{SplitRE} eq ";") {
	@subchunks = split /;/, $sentence;
      } elsif ($args{SplitRE} eq ",") {
	@subchunks = split /,/, $sentence;
      } elsif ($args{SplitRE} eq " ") {
	@subchunks = split / /, $sentence;
      }
      while (@subchunks) {
	my $chunk = shift @subchunks;
	push @chunks, $chunk;
	if (@subchunks) {
	  # push @chunks, ";";
	}
      }
      if (@sentences) {
	# push @chunks, ".";
      }
    }
    # now handle this

    # do a dynamic programming solution to determine the best fit, for
    # now, just try to pack it in

    my @result;
    foreach my $chunk (@chunks) {
      if (length($chunk) > $args{Size}) {
	if ($args{SplitRE} eq ";") {
	  push @result, @{IntelligentSplit(Text => $chunk, Size => $args{Size}, SplitRE => ",")};
	} elsif ($args{SplitRE} eq ",") {
	  push @result, @{IntelligentSplit(Text => $chunk, Size => $args{Size}, SplitRE => " ")};
	} elsif ($args{SplitRE} eq " ") {
	  my @res = $chunk =~ /(.{$args{Size}})*/;
	  push @result, @res;
	}
      } else {
	push @result, $chunk;
      }
    }
    # condense results as appropriate
    my $current = "";
    my @final;
    while (@result) {
      my $latest = shift @result;
      if (length($current.$args{SplitRE}.$latest) < $args{Size}) {
	if ($current) {
	  $current .= $args{SplitRE}.$latest;
	} else {
	  $current = $latest;
	}
      } else {
	push @final, $current;
	$current = $latest;
      }
    }
    if ($current) {
      push @final, $current;
    }

    return \@final;
  } else {
    return [$text];
  }
}
