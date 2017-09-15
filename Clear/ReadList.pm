package Clear::ReadList;

use Clear::Doc;
use Data::Dumper;
use Manager::Dialog qw (Message ApproveCommands SubsetSelect Choose);
use MyFRDCSA;
use PerlLib::SwissArmyKnife;

use Data::Dumper;
use WWW::Mechanize;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / ID Documents MetaDataFile Queue Hash CurrentDoc Entries /

  ];

sub init {
  my ($self,%args) = @_;
  $self->ID($args{ID});
  $self->Hash({});
  $self->Queue([]);
  $self->LoadMetaData;
  my $websitedir;
  if (defined $UNIVERSAL::clear) {
    $websitedir = $UNIVERSAL::clear->WebsiteDir || "/tmp/websites";
    $UNIVERSAL::clear->WebsiteDir($websitedir);
  }

  if (exists $args{ReadList} and -e $args{ReadList}) {
    @entries = CatSplit($args{ReadList});
  } elsif ($args{ReadList}) {
    @entries = @{$args{ReadList}};
  }
  $self->Entries(\@entries);
}

sub ProcessReadList {
  my ($self,%args) = @_;
  my $i = 0;
  my @entries = @{$self->Entries};
  while (@entries) {
    my $file = shift @entries;
    if ($file and $file !~ /^\s*#/) { # make sure not a comment
      # take care of the case of file:///stuff
      if (-d $file) {		# if a directory
	my @matches = ();
	foreach my $l (split /\n/,`find $file`) {
	  $self->Add
	    (
	     File => $l,
	     Order => $i++,
	    ) if -f $l;
	}
      } elsif (-f $file) {
	if ($file =~ /\.chm$/i) {
	  Message
	    (Message =>
	     "this is a chm file, extracting it and indexing its TOC...");
	  my $outdir = "/tmp/chm";
	  if (-d $outdir) {
	    ApproveCommands(Commands => ["rm -rf $outdir"],
			    Method => "parallel");
	  }
	  system "extract_chmLib \"$file\" $outdir";
	  my $tocfile = `find $outdir | grep -E "toc.(html|hhc)"`;
	  chomp $tocfile;
	  print "<TOCFILE: $tocfile>\n";
	  # my @files = $self->AddTocFile("file://".$tocfile);
	  my @files = $self->GetOrder("file://".$tocfile);
	  print Dumper({Files => \@files});
	  foreach my $f (@files) {
	    if ($f =~ /^file:\/\/(.*)$/) {
	      $self->Add
		(
		 File => $1,
		 Order => $i++,
		) if $1;
	    }
	  }
	} else {
	  $self->Add
	    (
	     File => $file,
	     Order => $i++,
	    );
	}
      } elsif ($file =~ /^(ht|f)tp:\/\/(([^\/]+)\/?.*)$/) {
	# make sure to select proper dir
	# extract out what the directory is going to be
	my @docs;
	if (exists $UNIVERSAL::clear->Config->CLIConfig->{-s}) {
	  # spidering enabled
	  @docs = $self->RetrievePapers($file);
	} elsif (exists $UNIVERSAL::clear->Config->CLIConfig->{'--next'}) {
	  @docs = $self->GetOrder($file);
	} else {
	  @docs = ($file);
	}
	my $websitedir = $UNIVERSAL::clear->WebsiteDir;
	foreach my $doc (reverse @docs) {
	  if ($doc =~ /^(ht|f)tp:\/\/(([^\/]+)\/?.*)$/) {
	    $command = "wget -N -P \"".$websitedir."\" -xN \"$doc\" >> /tmp/log 2>> /tmp/log";
	    print "$command\n";
	    `$command`;
	    my $res = `cat /tmp/log`;
	    my $line = [grep /./, split /\n/,$res]->[-1];
	    if ($line =~ /.*? - \`(.*?)\' saved/ or
		$line =~ /Server file no newer than local file \`(.*?)\' -- not retrieving./) {
	      my $fileloc = $1;
	      Message(Message => "adding $fileloc");
	      unshift @entries, $fileloc;
	    }
	  }
	}
      } elsif ($file =~ /^file:\/\/(.*)$/) {
	if (exists $UNIVERSAL::clear->Config->CLIConfig->{'--next'}) {
	  my @files = $self->GetOrder($file);
	  foreach my $f (@files) {
	    if ($f =~ /^file:\/\/(.*)$/) {
	      $self->Add
		(
		 File => $1,
		 Order => $i++,
		) if -f $1;
	    }
	  }
	} else {
	  $self->Add
	    (
	     File => $1,
	     Order => $i++,
	    ) if -f $1;
	}
      } elsif ($file =~ /^Liferea$/) {
	# load up the contents of liferea just queue up the queues,
	# but we need it to do it temporally, reading either forward
	# to backward, or backward to forward.

      } elsif (1) {
	# test whether is a debian package
	# FIXME: this is messy
	# foreach my $l (split /\n/,`dlocate $file | grep -E '(/man/|/doc/)' | sed -e 's/.*: //'`) {
	#   $self->Add(File => $l,Order => $i++) if -f $l;
	# }
      } else {
	Message(Message => "Unknown file <$file> in virtual readlist");
      }
    }
  }
}

sub AddTocFile {
  my ($self,$tocfile) = (shift,shift);
  my $mech = WWW::Mechanize->new();
  print "Getting <$url>\n";
  $mech->get($tocfile);
  my @links = $mech->find_all_links( url_regex => qr/\.(html?|hhc)$/i );
  my @retlinks;
  foreach my $l (@links) {
    push @retlinks, $l->url_abs;
  }
  return @retlinks;
}

sub GetOrder {
  my ($self,$url) = (shift,shift);
  my $mech = WWW::Mechanize->new();
  $mech->get($url);
  my @links;
  my $link = 1;
  do {
    $link = undef;
    # $link = $mech->find_link( text_regex => qr/^\s*next\s*$/i );
    $link = $mech->find_link( text_regex => qr/^\s*next/i );
    if ($link) {
      my $url = $link->url_abs->as_string;
      push @links, $url;
      print "adding ".$url."\n";
      $mech->get($url);
    }
  } while (defined $link);
  if (! scalar @links) {
    my $content = $mech->content;
    @links = map {"file:///tmp/chm/$_"} ($content =~ /<param name="Local" value="([^"]+?)">/sg);
  }
  return @links;
}

sub RetrievePapers {
  my ($self,$item) = (shift,shift);
  my $mech = WWW::Mechanize->new();
  my $selection = {};
  my (@matches,%selection);
  my $conf = $UNIVERSAL::clear->Config->CLIConfig;
  my $depth = defined $conf->{-s} ? $conf->{-s} : 1;
  print "<depth: $depth>\n";
  # iterate through all links depth deep
  my @newitems = ($item);
  my @items;
  my @papers = ();
  for ($i = 0; $i < $depth; ++$i) {
    my @items = @newitems;
    foreach my $l (@items) {
      print "trying $l\n";
      $mech->get($l);
      foreach my $link ($mech->links()) {
	if ($link->tag() eq "a") {
	  my $href = $link->url_abs;
	  if ($href =~ /\.(ps|ps.gz|ps.z|pdf|doc)$/i) {
	    push @papers, $href;
	  } elsif ($href =~ /\.(html?|hhc|css|php)$/i) {
	    push @newitems, $href;
	  }
	}
      }
    }
  }
  return SubsetSelect
    (Set => \@papers,
     Selection => $selection);
}

sub Process {
  my ($self,%args)  = @_;
  my $conf = $UNIVERSAL::clear->Config->CLIConfig;
  if (exists $conf->{'-c'}) {
    my @commands;
    foreach my $doc ($self->ListDocuments) {
      my $res = $self->CleanVoys($doc->OriginalFile);
      push @commands, $res if $res;
    }
    if (@commands) {
      ApproveCommands(Commands => \@commands,
		      Method => "parallel");
    }
  }
  if ($UNIVERSAL::clear->Mode eq "read" or exists $conf->{'-o'}) {
    $self->Queue([$self->ListUnreadDocuments]);
    foreach my $doc (@{$self->Queue}) {
      $self->Hash->{$doc->OriginalFile} = $doc;
    }
    $self->ResumeReading;
  }
  if (exists $conf->{'-q'}) {
    $self->ReviewMaterial;
  }
}

sub CleanVoys {
  my ($self,$file) = (shift,shift);
  if (-d $file) {
    return "rm ".join(" ",map {"\"$_\""} split /\n/,`find \"$file\" | grep '\\.voy\$'`)." ".
      join(" ",map {"\"$_\""} split /\n/,`find \"$file\" | grep '\\.voy.gz\$'`)."\n";
  } elsif (-e "$file.voy") {
    return "rm \"$file.voy\"";
  } elsif (-e "$file.voy.gz") {
    return "rm \"$file.voy.gz\"";
  } else {
    Message(Message => "File not found <$file>");
    return 0;
  }
}

sub ResumeReading {
  my ($self,%args) = @_;
  while (@{$self->Queue} and $self->ShouldBeReading) {
    my $doc = shift @{$self->Queue};
    $self->CurrentDoc($doc);
    $UNIVERSAL::clear->MyGUI->UpdateTabName(ID => $self->ID);
    $doc->Read;
    if ($doc->ShouldBeReading) {
      # the document is destroyed after it is read, since otherwords, if
      # the contents  changed, the  voy file would  not, as is  the case
      # when using /tmp/clear
      delete $self->Documents->{$doc->OriginalFile};
      $doc->DESTROY;
    } else {
      unshift @{$self->Queue}, $doc;
    }
  }
  if (! @{$self->Queue}) {
    print "No More Documents\n";
  }
}

sub ShouldBeReading {
  my ($self,%args) = @_;
  return $UNIVERSAL::clear->MyGUI->ActiveReadList == $self->ID;
}

sub JumpTo {
  my ($self,%args) = @_;
  my @docs = sort {$a->Order <=> $b->Order} $self->ListDocuments;
  my $res = Choose(map $_->OriginalFile, @docs);
  my $i = 0;
  while ($i < @docs and
	 $docs[$i]->OriginalFile ne $res) {
    ++$i;
  }
  if ($i < @docs) {
    splice @docs,0,$i;
    $self->Queue(\@docs);
    return 1;
  }
  return 0;
}

sub OldResumeReading {
  my ($self,%args) = @_;
  foreach my $doc ($self->ListUnreadDocuments) {
    $doc->Read;
  }
  print "No More Documents\n";
}

sub ReviewMaterial {
  my ($self,%args) = @_;
  # take  the current document,  combine the  sentences we  have read,
  # summarize them, extract important words, ask questions
  foreach my $doc ($self->ListUnreadDocuments) {
    if (-f $doc->ParsedFile) {
      $doc->Review;
    }
  }
}

sub ListDocuments {
  my ($self,%args) = @_;
  return values %{$self->Documents};
}

sub ListUnreadDocuments {
  my ($self,%args) = @_;
  my @readinglist;
  foreach my $doc ($self->ListDocuments) {
    if (! $doc->HasBeenRead) {
      push @readinglist, $doc;
    }
  }
  return sort {$a->Order <=> $b->Order} @readinglist;
}

sub LoadMetaData {
  my ($self,%args) = @_;
  $self->Documents({});
}

sub Add {
  my ($self,%args) = @_;
  my $file = $args{File};
  my $order = $args{File};
  if (! -f $file and defined $UNIVERSAL::clear and
      -f ConcatDir($UNIVERSAL::clear->SystemDir,$file)) {
    $file = ConcatDir($UNIVERSAL::clear->SystemDir,$file);
  }
  my @files;
  if ($file =~ /\.rl$/i) {
    if (-f $file) {
      my $c = read_file($file);
      my @tmp = split /\n/, $c;
      push @files, @tmp;
    }
  } else {
    push @files, $file;
  }
  foreach my $file (@files) {
    $self->Documents->{$file} =
      Clear::Doc->new
	(
	 OriginalFile => $file,
	 ParsedFile => $file . ".voy",
	 CompressedParsedFile => $file . ".voy.gz",
	 ReadListID => $self->ID,
	);
    $self->Documents->{$file}->Order($order++);
  }
}

sub CatSplit {
  my $file = shift;
  my $text = read_file($file);
  split /\n/, $text;
}

1;
