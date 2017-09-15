package Clear::DocDataXML;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / Contents Data / ];

sub init {
  my ($self,%args) = @_;
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
  return (($i >= 0) && 
	  ($i < scalar $self->Contents) &&
	  (defined $self->Contents->[$i]));
}

sub Read {
  my ($self,$i) = @_;
  if (defined($self->Contents->[$i])) {
    if (! defined($self->Data->[$i])) {
      $self->Data->[$i] = {};
    }
    $self->Data->[$i]->{StartTime} = `date`;
    if(length($self->Contents->[$i]) < 750) {
      return $self->Contents->[$i];
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
    $self->Data->[$i]->{EndTime} = `date`;
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


1;
