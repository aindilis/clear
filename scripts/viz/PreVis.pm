package PreVis;

use Capability::TextAnalysis;
use System::WWW::GoogleImages;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyTagger MyGoogleImages MyNER Image MySayer /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Image([]);

  $self->MyGoogleImages
    (System::WWW::GoogleImages->new());

  $self->CacheObj
    (Cache::FileCache->new
     ("/var/lib/myfrdcsa/codebases/internal/clear/data/FileCache/clear-visualizer2"));

  $self->Cacher
    (WWW::Mechanize::Cached->new
     (
      cache => $self->CacheObj,
      timeout => 15,
     ));

  $self->MySayer
    (Sayer->new
     (
      DBName => "sayer_clear_visualize2",
     ));

  # add an ability here to test for installed capabilities

  $self->MyTextAnalysis
    (Capability::TextAnalysis->new
     (
      Sayer => $self->MySayer,
      DontSkip => {
		   "NounPhraseExtraction" => 1,
		   "NamedEntityRecognition" => 1,
		   "Tokenization" => 1,
		   "TermExtraction" => 1,
		   "SemanticAnnotation" => 1,
		   "MontyLingua" => 1,
		   "DateExtraction" => 1,
		   # # "FactExtraction" => 1,
		   # "CoreferenceResolution" => 1,
		   # "WSD" => 1,
		   # # "SpeechActClassification" => 1,
		   # # "CycLsForNP" => 1,
		  },
     ));
}

sub VisualizeText {
  my ($self,%args) = @_;
  my $debug = 0;
  # need a  general purpose thing  for noticing interesting  items, or
  # previously  undefined items,  or predicting  which items  could be
  # useful

  my $goahead = 1;
  my @best;
  if (1) {
    my $phrases =
      {
       $self->MyTagger->get_max_noun_phrases
       ($self->MyTagger->add_tags
	($args{Text}))
      };

    my @keys = keys %$phrases;

    my $numberofphrasestouse = $self->ChooseRandomFavoringFirst
      (
       Count => min(4,scalar @keys),
       Decay => 0.7,
      );

    print Dumper(\@keys) if $debug;
    if (defined $numberofphrasestouse) {

      foreach my $i (0 .. $numberofphrasestouse) {
	my $integer = $self->ChooseRandomFavoringFirst
	  (
	   Count => scalar @keys,
	   Decay => 0.86,
	  );

	my $removed = RemoveIthElementFromList($i,\@keys);
	push @best, $removed if $removed;
      }
    }
  }
#   if (1) {
#     my $nerres = $self->MyNER->NERExtract
#       (Text => $args{Text});
#     foreach my $item (@{$nerres}) {
#       push @best, join(" ",@{$item->[0]});
#     }
#   }

  print Dumper({BEST => \@best}) if $debug;

  # select three of these
  # first kill all the existing xview?
  # system "killall xview";
  foreach my $k (@best) {
    if ($goahead or Approve("Visualize ($k)?")) {
      my @res = $self->MyGoogleImages->Search(Search => $k);

      # select probability wise to obtain the best results here we
      # would use Math::GSL as in
      # /var/lib/myfrdcsa/codebases/internal/clear/scripts/rand-dist-test.pl,
      # but it's not available for amd64 at time of writing, so write
      # our own bs

      # choose a random integer, favoring sooner ones
      my $numberofimages = $self->ChooseRandomFavoringFirst
	(
	 Count => min(4,scalar @res),
	 Decay => 0.4,
	);

      if (defined $numberofimages) {
	foreach my $i (0 .. $numberofimages) {
	  my $integer = $self->ChooseRandomFavoringFirst
	    (
	     Count => scalar @res,
	     Decay => 0.86,
	    );

	  my $item = RemoveIthElementFromList($i,\@res);
	  my $ref = ref $item;
	  if ($ref eq "KBFS::Cache::Item") {
	    $item->Retrieve;
	    $self->View
	      (
	       Image => $item->Loc,
	       Comment => $k,
	      );
	  }
	}
      }
      $self->MyGoogleImages->Cache->ExportMetadata;
    }
  }
}

sub RemoveIthElementFromList {
  my ($i,$list) = @_;

  if ($i >= 0 and $i <= $#$list) {
    my $ret = $list->[$i];
    my @res;
    foreach my $j (0..$#$list) {
      if ($j > $i) {
	$list->[$j-1] = $list->[$j];
      }
    }
    delete $list->[$#$list];
    return $ret;
  }
}

sub min {
  my ($a, $b) = @_;
  if ($a < $b) {
    return $a;
  } else {
    return $b;
  }
}

sub Top {
  my $c = shift;
  return splice(@_,0,$c);
}

sub View {
  my ($self,%args) = @_;
  my $image = $args{Image};
  print "Image Comment: <$args{Comment}>\n";
  $args{Comment} =~ s/\W/_/g if defined $args{Comment};

  defined($pid = fork()) or die "Cannot fork()!\n";
  if ($pid) {
    # parent
    # store the pid number
    push @{$self->Image}, $pid;
  } else {
    # child
    exec "display -size x200 -comment \"$args{Comment}\" \"$image\"";
  }

  # now end any processes that we should
  while (scalar @{$self->Image} > 10) {
    my $pid = shift @{$self->Image};
    print "$pid\n" if $debug;
    kill 9, $pid;
  }
}

sub ChooseRandomFavoringFirst {
  my ($self,%args) = @_;
  my $debug = 0;
  print Dumper(\%args) if $debug;
  my $total1 = 0;
  my $factor = 10;
  foreach my $i (0..($args{Count}-1)) {
    $total1 += $factor;
    $factor *= $args{Decay};
  }
  my $cutoff = rand($total1);
  print "Cutoff: $cutoff\n" if $debug;

  $factor = 10;
  my $total2 = 0;
  my $touched = 0;
  foreach my $i (0..($args{Count}-1)) {
    $total2 += $factor;
    $factor *= $args{Decay};
    if ($total2 > $cutoff) {
      print "returned $i\n" if $debug;
      return $i;
    }
  }
  print "returned undef\n" if $debug;
}

1;
