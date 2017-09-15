package Clear::Voy::Pair;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / VoyFile CompressedVoyFile OrigFile /

  ];

sub init {
  my ($self,%args) = @_;
  $self->VoyFile($args{VoyFile});
  $self->CompressedVoyFile
    ($args{CompressedVoyFile} ||
     $self->VoyFile.".gz");
  $self->OrigFile($args{OrigFile});
}

sub SPrintOneLiner {
  my ($self,%args) = @_;
  return $self->VoyFile;
}

sub ConvertVoyFormatToCurrentVersion {
  my ($self,%args) = @_;
  my $vf = "voys/test.voy";

  my $c = `cat "$vf"`;
  my $e = eval $c;

  # print Dumper($e);

  my $re = {
	    Data => [],
	    Contents => $e->{Contents},
	   };

  foreach my $entry (@{$e->{Data}}) {
    my $st = ConvertDateFormat($entry->{StartTime});
    my $et = ConvertDateFormat($entry->{EndTime});
    push @{$re->{Data}},
      {
       S => $st,
       E => $et-$st,
       R => $entry->{Read}
      };
  }

  my $OUT;
  open(OUT,">voys/out.voy") or die "cannot open\n";
  print OUT Dumper($re);
  close(OUT);
}

1;
