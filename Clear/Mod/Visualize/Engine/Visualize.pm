package Clear::Mod::Visualize::Engine::Visualize;

# this could also be useful for coauthor

use Capability::NER;
use Manager::Dialog qw(Approve);
use System::WWW::GoogleImages2;

use Data::Dumper;
use Image::Magick;
use Lingua::EN::Tagger;
use MIME::Base64;
use Tk;

# use warnings;
# use strict;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyTagger MyGoogleImages MyNER Image Count Debug Simulate /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyGoogleImages
    (System::WWW::GoogleImages2->new());
  $self->MyTagger
    (Lingua::EN::Tagger->new(stem => 0));
  $self->MyNER
    (Capability::NER->new);
  $self->MyNER->StartServer;
  $self->Image([]);
  $self->Count(0);
  $self->Debug(0);
  $self->Simulate(1);
}

sub VisualizeText {
  my ($self,%args) = @_;
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

    #     my $numberofphrasestouse = $self->ChooseRandomFavoringFirst
    #       (
    #        Count => min(2,scalar @keys),
    #        Decay => 0.95,
    #       );

    my $numberofphrasestouse = int(rand 3);
    print Dumper(\@keys) if $self->Debug;
    if (defined $numberofphrasestouse) {

      foreach my $i (0 .. $numberofphrasestouse) {
	my $integer = $self->ChooseRandomFavoringFirst
	  (
	   Count => scalar @keys,
	   Decay => 0.95,
	  );

	my $removed = RemoveIthElementFromList($i,\@keys);
	push @best, $removed if $removed;
      }
    }
  }
  if (1) {
    my $nerres = $self->MyNER->NERExtract
      (Text => $args{Text});
    foreach my $item (@{$nerres}) {
      push @best, join(" ",@{$item->[0]});
    }
  }

  print Dumper({BEST => \@best}) if $self->Debug;

  # select three of these
  # first kill all the existing xview?
  # system "killall xview";
  foreach my $k (@best) {
    print "\t".$k."\n";
    next if $self->Simulate;
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
	 Count => min(3,scalar @res),
	 Decay => 0.7,
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
	    if ($self->Simulate) {
	      print Dumper($item);
	    } else {
	      $item->Retrieve;
	      $self->View
		(
		 Image => $item->Loc,
		 Comment => $k,
		);
	    }
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
  print "Image Comment: <$args{Comment}>\n" if $self->Debug;
  $args{Comment} =~ s/[^0-9a-zA-Z]/_/g if defined $args{Comment};

  defined($pid = fork()) or die "Cannot fork()!\n";
  if ($pid) {
    # parent
    # store the pid number
    push @{$self->Image}, $pid;
  } else {
    # child
    # exec "display -size x200 -comment \"$args{Comment}\" \"$image\"";
    print "OPENING image $image\n" if $self->Debug;
    my $picture = Image::Magick->new;
    $picture->Read($image);
    $picture->Set(magick=>'gif');
    my $blob = $picture->ImageToBlob();
    if (defined $blob) {
      my $content = encode_base64( $blob ) or die $!;
      my $mw  = MainWindow->new();
      my $tkimage = $mw->Photo(-data => $content);
      $mw->title($args{Comment});
      $mw->Label(-image => $tkimage)->pack(-expand => 1, -fill => 'both');
      MainLoop;
    }
    exit(0);
  }
  print "CREATED PID $pid\n" if $self->Debug;

  # now end any processes that we should
  print Dumper($self->Image) if $self->Debug;

  while (scalar @{$self->Image} > 5) {
    my $pid = shift @{$self->Image};
    print "CLOSING PID $pid\n" if $self->Debug;
    kill 9, $pid;
    system "kill -9 $pid";
  }
  $self->Count($self->Count + 1);
  if (!($self->Count % 10)) {
    foreach my $line (split /\n/, `ps aux | grep display`) {
      print "PID:  $line\n" if $self->Debug;
    }
  }
}

sub ChooseRandomFavoringFirst {
  my ($self,%args) = @_;
  print Dumper(\%args) if $self->Debug;
  my $total1 = 0;
  my $factor = 10;
  foreach my $i (0..($args{Count}-1)) {
    $total1 += $factor;
    $factor *= $args{Decay};
  }
  my $cutoff = rand($total1);
  print "Cutoff: $cutoff\n" if $self->Debug;

  $factor = 10;
  my $total2 = 0;
  my $touched = 0;
  foreach my $i (0..($args{Count}-1)) {
    $total2 += $factor;
    $factor *= $args{Decay};
    if ($total2 > $cutoff) {
      print "returned $i\n" if $self->Debug;
      return $i;
    }
  }
  print "returned undef\n" if $self->Debug;
}

1;

