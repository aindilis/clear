package Clear::Voy::Index;

# voyindex should  use file name  information to help  posit relations
# between existing voys.   if they in the same  directory tree, and if
# so esp if their names match a pattern (e.g. ch1.pdf, ch2.pdf)

# should try to extract author information etc (use paracite? a)

use Clear::Doc;
use Clear::DocData;
use Clear::Voy::Pair;
use Manager::Dialog qw(ApproveCommands);
use PerlLib::MySQL;
use PerlLib::TFIDF;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Pairs StorageFile DateHash Entries MyMySQL MyTFIDF /

  ];

sub init {
  my ($self,%args) = @_;
  $self->Pairs({});
  $self->StorageFile
    ($args{StorageFile} || "data/voy.idx");
  $self->DateHash
    ({
      "Jan" => 1,
      "Feb" => 2,
      "Mar" => 3,
      "Apr" => 4,
      "May" => 5,
      "Jun" => 6,
      "Jul" => 7,
      "Aug" => 8,
      "Sep" => 9,
      "Oct" => 10,
      "Nov" => 11,
      "Dec" => 12,
     });
}

sub ConvertDateFormat {
  my ($self,$date) = @_;
  if ($date =~ /^\w+ (\w+) (\d+) (\d+):(\d+):(\d+) EDT (\d+)$/) {
    return $6.$self->DateHash->{$1}."$2$3$4$5";
  }
}

sub Index {
  my ($self,%args) = @_;
  # find all the voys on a given system and build an index
  # simply do a locate of all the voys
  # system "sudo /usr/bin/updatedb";
  my $voys = `locate voy | grep '\.voy.gz\$'`;
  foreach my $f (split /\n/,$voys) {
    if (-f $f) {
      my $origfile = $f;
      $origfile =~ s/\.voy.gz$//;
      if (-f $origfile) {
	my $pair = Clear::Voy::Pair->new
	  (VoyFile => $origfile.".voy",
	   CompressedVoyFile => $origfile.".voy.gz",
	   OrigFile => $origfile);
	$self->Pairs->{$f} = $pair;
      }
    }
  }
  $self->Save;
}

sub Save {
  my ($self,%args) = @_;
  my $OUT;
  open(OUT,">".$self->StorageFile) or die "Cannot open storage file for saving\n";
  print OUT Dumper($self->Pairs);
  close(OUT);
}

sub Load {
  my ($self,%args) = @_;
  my $f = $self->StorageFile;
  if (-f $self->StorageFile) {
    my $c = `cat "$f"`;
    my $e = eval $c;
    $self->Pairs($e);
  }
}

sub Print {
  my ($self,%args) = @_;
  foreach my $pair (values %{$self->Pairs}) {
    print $pair->SPrintOneLiner."\n";
  }
}

sub ConvertVoysInVoyIndex {
  my ($self,%args) = @_;
  # convert all voys in an indexed voy to the current voy version
  my @c;
  foreach my $pair (values %{$self->Pairs}) {
    if (-f $pair->VoyFile) {
      push @c, "gzip '".$pair->VoyFile."'";
    }
  }
  ApproveCommands
    (Commands => \@c,
     Method => "parallel");
}

sub LoadEntries {
  my ($self,%args) = @_;
  # generate a user knowledge model from an index of voys
  # load each document, extract contents, and perform TFIDF on them.
  $self->MyMySQL(PerlLib::MySQL->new(DBName => "clear"));
  foreach my $pair (values %{$self->Pairs}) {
    if (-f $pair->CompressedVoyFile) {
      print $pair->OrigFile."\n";
      my $f = $pair->CompressedVoyFile;
      my $c = Clear::Doc->new
	  (OriginalFile => $pair->OrigFile,
	   ParsedFile => $pair->VoyFile,
	   CompressedParsedFile => $pair->CompressedVoyFile);
      $c->Parse;
      if (ref $c->MyDocData eq "Clear::DocData") {
	my @l = map {$self->MyMySQL->Quote
		       ($_)} ($pair->OrigFile,
			      $pair->VoyFile,
			      $pair->CompressedVoyFile,
			      join("\n",@{$c->MyDocData->Contents}));
	# insert them into a mysql database
	my $s = "insert into readings values (NULL,".join(',',@l).")";
	$self->MyMySQL->Do(Statement => $s);

	# have to figure out when it was read.  Perhaps should just
	# have everything go into a database, and get of voy files at
	# any rate the whole system could stand to be worked out
	# better
      }
    }
  }
  $self->Entries($entries);
}

sub GenerateUserKnowledgeModelFromVoyIndex {
  my ($self,%args) = @_;
  # generate a user knowledge model from an index of voys
  $self->LoadEntries;
  $self->MyTFIDF(PerlLib::TFIDF->new());
  $self->MyTFIDF->Entries($self->Entries);
  $self->MyTFIDF->ComputeTFIDF;
}

sub ConceptSearch {
  my ($self,%args) = @_;
  # search through readings
}

sub GraphReadingDependencies {
  my ($self,%args) = @_;
  # search through readings
}

sub GraphReadingTimeline {
  my ($self,%args) = @_;
  # search through readings

  # this is  a function  that is  designed to list  a summary  of what
  # documents you read, when,  listing interruptions and everything in
  # a graphical and or textual format

}

sub GraphContentAreas {
  my ($self,%args) = @_;
  # this  is to generate  a visual  depiction of  the user's  areas of
  # training based on the reading files, to give a quick impression of
  # the user's strengths

  # has graphical or textual output

}

sub GenerateReadingList {
  my ($self,%args) = @_;
  # based on the knowledge model, generate a reading list that teaches
  # user new things

  # try to detect  what type of reading will  be productive, do ranges
  # of files, not necessarily whole files
}

sub InteractiveReader {
  my ($self,%args) = @_;

  # use  a  telepathic  interface  (eye  tracking here),  and  have  a
  # changing content graph, and depending what the user looks at, read
  # them from those areas!!!!!!!!!!!!!!!
}

1;
