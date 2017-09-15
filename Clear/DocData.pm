package Clear::DocData;

use Data::Dumper;
use Lingua::EN::Sentence qw(get_sentences);

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / MyDoc Contents ContentsSize Data / ];

sub init {
  my ($self,%args) = @_;
  print 'DocData Invocation Instance '.$args{Instance}."\n";
  $self->MyDoc($args{Doc});
  print Dumper({MyDocMyDoc => $self->MyDoc}) if 0;
  $self->Contents($args{Contents} || []);
  $self->Data($args{Data} || []);
}

sub GetLatest {
  my ($self) = @_;
  my $i = 0;
  my $loop = 1;
  do {
    if (defined($self->Data->[$i])
	&& $self->Data->[$i]->{Read}) {
      ++$i;
    } else {
      $loop = 0;
    }
  } while ($loop);
  if ($i != scalar $self->Contents) {
    return $i;
  } else {
    return -1;
  }
}

sub CanRead {
  my ($self,$i) = @_;
  if (! defined $self->ContentsSize) {
    $self->ContentsSize(scalar @{$self->Contents});
  }
  return (($i >= 0) && 
	  ($i < $self->ContentsSize) &&
	  (defined $self->Contents->[$i]));
}

sub Read {
  my ($self,$i) = @_;
  my $size = 750;
  if (defined($self->Contents->[$i])) {
    if (! defined($self->Data->[$i])) {
      $self->Data->[$i] = {};
    }
    $self->Data->[$i]->{StartTime} = `date`;
    if (length($self->Contents->[$i]) < $size) {
      return [$self->Contents->[$i]];
    } else {
      # have to split it into two or more items

      # work on splitting it down based on semicolons, then colons,
      # then commas
      return $self->IntelligentSplit
	(
	 Text => $self->Contents->[$i],
	 Size => $size,
	 SplitRE => ";",
	);
    }
  }
}

sub MarkRead {
  my ($self,$i) = @_;
  if (defined($self->Contents->[$i])) {
    if (! defined($self->Data->[$i])) {
      $self->Data->[$i] = {};
    }
    $self->Data->[$i]->{Read} = 1;
    my $datetime = `date`;
    $self->Data->[$i]->{EndTime} = $datetime;
    print Dumper({MyDocMyDoc => $self->MyDoc}) if 0;

    my $docid = 1;
    my $epoch = `date "+%s"`;
    chomp $epoch;

    # KBS2::Client
    my $res1 = $UNIVERSAL::agent->QueryAgent
      (
       Receiver => "KBS2",
       Data => {
		_DoNotLog => 1,
		Command => 'assert',
		Formula => ['r',['d',$docid],['s',$i],['to',$epoch]],
		Method => 'MySQL',
		Database => 'freekbs2',
		Context => 'Org::FRDCSA::Clear::DocData',
		Asserter => 'guest',
		# Quiet => undef,
		# OutputType => undef,
		Flags => {
			  AssertWithoutCheckingConsistency => 1,
			 },
		Data => $args{Data},
		Type => $type,
		Force => $args{Force},
	       },
      );
    # print Dumper({Res1 => $res1});
  }
}

sub ComputeReadingTime {
  my ($self,%args) = @_;

}

sub EstimateEntireReadingTime {
  my ($self,%args) = @_;
  # what is the current duration
  $duration = "0.35";
  # how many words are there?
  my @words = grep /../, split /\W+/;
  my @sentences = @{get_sentences($self->Contents)};
  my $swt = 1;
  my $sst = 1;
  my $est = $duration * ((scalar @words) * $swt + (scalar @sentences) * $sst);
  $self->ETC($est);
}


sub IntelligentSplit {
  my ($self,%args) = @_;
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
	  push @result, @{$self->IntelligentSplit(Text => $chunk, Size => $args{Size}, SplitRE => ",")};
	} elsif ($args{SplitRE} eq ",") {
	  push @result, @{$self->IntelligentSplit(Text => $chunk, Size => $args{Size}, SplitRE => " ")};
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

sub DESTROY {
  my ($self, %args) = @_;
  print Dumper({
		DestroyKeys => [keys %$self],
		Args => \%args,
	       });
  $self->MyDoc->SaveMetaData;
  $self->MyDocData("");
}

1;
