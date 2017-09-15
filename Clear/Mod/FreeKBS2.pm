package Clear::Mod::FreeKBS2;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw /  /

  ];

sub init {
  my ($self,%args) = @_;
}

sub LoadMetaData {
  my ($self) = (shift);
  my $context = "Org::FRDCSA::Clear::Text::<FILENAME>";
  $args{Context};

  my $command = "/var/lib/myfrdcsa/codebases/internal/freekbs2/kbs2 $context show 2> /dev/null";
  my $data = `$command`;

  if (-f $self->CompressedParsedFile) {
    $command = "gunzip -d -c ".$self->QuotedCompressedParsedFile;
  } elsif (-f $self->ParsedFile) {
    $command = "cat ".$self->QuotedParsedFile;
  }
  $self->MyDocData(eval `$command`);
}

sub SaveMetaData {
  my ($self) = (shift);
  if (defined $self->MyDocData) {
    if ($self->MyDocData) {
      open (OUT,">".$self->ParsedFile);
      # print $self->MyDocData;
      print OUT Dumper($self->MyDocData);
      close (OUT);
      system "gzip -f ".$self->QuotedParsedFile;
    }
  }
}

1;
