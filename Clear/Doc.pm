package Clear::Doc;

use Academician::Util;
use Clear::DocData;
use Clear::Mod::Visualize;
use Manager::Dialog qw (Message QueryUser2 SubsetSelect);
use MyFRDCSA;
use PerlLib::Chase;
use PerlLib::RSSReader;
use PerlLib::SwissArmyKnife;
use Rival::Lingua::EN::Sentence qw (get_sentences);

use Data::Dumper;
use Error qw(:try);
use File::Temp;
use String::Similarity;
use Term::ReadKey;
use Text::Wrap;
use Time::HiRes qw (usleep);

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw( OriginalFile ChasedOriginalFile QuotedOriginalFile MyDocData
       ParsedFile QuotedParsedFile CompressedParsedFile
       QuotedCompressedParsedFile HasBeenRead Order HTMLConverter
       MyVisualizer Editor FileType DefaultTimeOut Stop Position
       MyText Paused Sleeping ReadListID PageNos CurrentPage )

  ];

sub init {
  my ($self,%args) = @_;
  $self->OriginalFile($args{OriginalFile});
  $self->ChasedOriginalFile(chase($self->OriginalFile));
  $self->QuotedOriginalFile("\"".$self->OriginalFile."\"");
  $self->ParsedFile($args{ParsedFile});
  $self->QuotedParsedFile("\"".$self->ParsedFile."\"");
  $self->CompressedParsedFile($args{CompressedParsedFile});
  $self->QuotedCompressedParsedFile("\"".$self->CompressedParsedFile."\"");
  $self->ReadListID($args{ReadListID});
  $self->PageNos([]);
  # $self->MyVisualizer
  #   (Clear::Mod::Visualize->new
  #    (EngineName => "Visualize2"));
  $self->DefaultTimeOut(0.05);
  if (! exists $UNIVERSAL::clear->Config->CLIConfig->{'--no-gui'}) {
    $UNIVERSAL::clear->MyGUI->Readers->Contents->{$self->ReadListID}->MyTabManager->Tabs->{Display}->Doc($self);
    $self->MyText($UNIVERSAL::clear->MyGUI->Readers->Contents->{$self->ReadListID}->MyTabManager->Tabs->{Display}->MyText);
  }
}

sub Parse {
  my ($self) = (shift);
  if ($self->MyDocData and
      $self->OriginalFile ne "/tmp/clear.txt") {
    # nothing to do
  } elsif ((-f $self->CompressedParsedFile or -f $self->ParsedFile) and
	   $self->OriginalFile ne "/tmp/clear.txt") {
    # load the file
    $self->LoadMetaData;
  } else {
    # must parse the file
    $self->DoParse;
  }
}

sub DoParse {
  my ($self) = (shift);
  # find out what file type the file is
  my $file = $self->OriginalFile;
  my $regex;
  if (defined $UNIVERSAL::clear and exists $UNIVERSAL::clear->Config->CLIConfig->{'-R'}) {
    # this means reject extensions
    $regex = $UNIVERSAL::clear->Config->CLIConfig->{'-R'};
    $regex =~ s/,/|/;
    $regex = "($regex)\$";
  }
  if ($regex and $file =~ /$regex/) {
    Message(Message => "Skipping file since extension is in Reject list");
  } elsif ($file =~ /\.voy(.gz)?$/i) {
    Message(Message => "Skipping voy file");
  } elsif ($file =~ /\.rl$/i) {
    Message(Message => "Recursive ReadList not yet supported");
    my $rl = Clear::ReadList->new
      (ReadList => $file);
    $rl->Process;
  } elsif ($file =~ /\.opml$/i) {
    Message(Message => "Reading RSS feed");
    my $rssreader = PerlLib::RSSReader->new(OPMLFile => $file);
    my $sentences = [];
    my $skip = 0;
    try {
      $sentences = get_sentences($rssreader->GetContents);
    }
      catch Error with {
	$skip = 1;
	Message(Message => "Skipping file since an error: cannot get sentences.\n");
      };
    if (! $skip) {
      my @sentences = $self->FilterSentences(@$sentences);
      print "DocData Invocation Instance 2-1\n";
      $self->MyDocData
	(Clear::DocData->new
	 (
	  Contents => \@sentences,
	  Data => [],
	  Doc => $self,
	  Instance => 1,
	 ));
      $self->SaveMetaData;
    }
  } else {
    print "f<<<$file>>>\n";
    my $type;
    if (defined $UNIVERSAL::clear and exists $UNIVERSAL::clear->Config->CLIConfig->{'-f'}) {
      $type = $UNIVERSAL::clear->Config->CLIConfig->{'-f'};
    }
    my $res = $UNIVERSAL::clear->MyToText->ToText
      (
       File => $self->OriginalFile,
       Type => $type,
       UseBodyTextExtractor => (defined $UNIVERSAL::clear and exists $UNIVERSAL::clear->Config->CLIConfig->{'--body'}),
       Unidecode => 1,
       CleanStrangeCharacters => 1,
       Raw => 1,
      );
    if ($res->{Success}) {
      $contents = $res->{Text};
      $res->{Text} =~ s/’/'/sg;
      #       if (!$contents and $file =~ /\.html?/i) {
      # 	my $htmlcontents = `cat \"$file\"`;
      # 	$contents = $self->Preprocess(Contents => $htmlcontents);
      #       }
      my $sentences = [];
      my $skip = 0;
      try {
	$sentences = get_sentences($contents);
      }
	catch Error with {
	  $skip = 1;
	  Message(Message => "Skipping file since an error: cannot get sentences.\n");
	};
      if (! $skip) {
	my @sentences = $self->FilterSentences(@$sentences);
	print "DocData Invocation Instance 2-2\n";
	$self->MyDocData
	  (Clear::DocData->new
	   (
	    Contents => \@sentences,
	    Data => [],
	    Doc => $self,
	    Instance => 2,
	   ));
	$self->SaveMetaData;
      }
    } elsif ($res->{Failure}) {
      print 'Failure: Reason: '.$res->{FailureReason}."\n";
    }
  }
}

sub Preprocess {
  my ($self,%args) = @_;
  if (! defined $self->HTMLConverter) {
    $self->HTMLConverter(PerlLib::HTMLConverter->new());
  }
  my $txt = $self->HTMLConverter->ConvertToTxt
    (Contents => $args{Contents});
  $txt =~ s/\P{IsASCII}/ /g;
  return $txt;
}


sub FilterSentences {
  my ($self,@sentences) = @_;
  # now let us be sure to clean up any nonsense via POS tagging
  # Add part of speech tags to a text
  foreach my $sentence (@sentences) {
    # print "<$sentence>\n";

    $sentence =~ s/(.)\1{4,}/ /g;
    $sentence =~ s/ \W / /g;
    $sentence =~ s/\|/ /g;
    $sentence =~ s// CLEAR-COMMAND-CONTROL-L-CLEAR-COMMAND /sg;
    $sentence =~ s/[\n\s]+/ /g;
    $sentence =~ s/ ?CLEAR-COMMAND-CONTROL-L-CLEAR-COMMAND ?//sg;

    # print "<$sentence>\n";
    # my $tagged_text = $UNIVERSAL::clear->Tagger->add_tags( $sentence );
    # print Dumper($tagged_text);
  }
  # # Get a list of all nouns and noun phrases with occurrence counts
  # my %word_list = $p->get_words( $text );
  # # Get a readable version of the tagged text
  # my $readable_text = $p->get_readable( $text );
  return @sentences;
}

sub CheckForUserInput {
  my ($self, %args) = @_;
  $UNIVERSAL::clear->Listen(TimeOut => $self->DefaultTimeOut);
  if (exists $UNIVERSAL::clear->Config->CLIConfig->{'-u'}) {
    # $UNIVERSAL::agent->Listen(TimeOut => $self->DefaultTimeOut);
    if (scalar @{$UNIVERSAL::clear->LastCommand}) {
      my $it = shift @{$UNIVERSAL::clear->LastCommand};
      print "RESPONSE: <$it>\n";
      return $it;
    }
  } else {
    ReadMode('cbreak');
    if (defined ($char = ReadKey(-1)) ) {
      ReadMode('normal');
      return $char;
    }
    ReadMode('normal');		# restore normal tty settings
  }
}

sub Read {
  my ($self) = (shift);
  $UNIVERSAL::clear->CurrentDoc($self);
  my $conf = $UNIVERSAL::clear->Config->CLIConfig;
  if (-f $self->OriginalFile or -f ConcatDir($UNIVERSAL::clear->SystemDir,$self->OriginalFile)) {
    if (! $self->HasBeenRead or $self->OriginalFile eq "/tmp/clear.txt") {
      $self->Parse;
      if ($self->MyDocData) {
	if (exists $conf->{'-o'}) {
	  $self->RecordToOggs
	    (
	     Contents => $self->MyDocData->Contents,
	     Dir => $conf->{'-o'},
	    );
	} else {
	  if (exists $conf->{'-e'}) {
	    $self->OpenInEditor;
	  }

	  if ($self->MyText) {
	    $self->MyText->configure(-state => "normal");
	    $self->MyText->delete('0.0','end');
	    my $i = 0;
	    foreach my $entry (@{$self->MyDocData->Contents}) {
	      $self->MyText->insert("end","$i  ".$entry."\n");
	      # $self->MyText->insert("end",$entry."\n");
	      ++$i;
	    }
	    $self->MyText->configure(-state => "disabled");
	    $self->MyText->tagConfigure('bgcolor', -background => "yellow");
	    $self->MyText->configure(-state => "disabled");
	  }

	  # print "(ffap \"".$self->ParsedFile."\")\n";
	  # print ";; Reading file:\n";
	  $self->Stop(0);
	  $self->SetPosition
	    ($self->MyDocData->GetLatest);
	  my $char;
	  while (! $self->Stop and $self->MyDocData->CanRead($self->Position) and $self->ShouldBeReading) {
	    if ($self->MyText) {
	      # $self->MyText->tagRemove('sel', ($self->Position).".0",  ($self->Position).".0 lineend");
	      # $self->MyText->tagDelete('bgcolor');
	      # $self->MyText->tagAdd('sel', ($self->Position+1).".0",  ($self->Position+1).".0 lineend");
	      if ($oldmethod) {
		$self->MyText->tagRemove('bgcolor', ($self->Position).".0",  ($self->Position).".0 lineend");
		$self->MyText->tagAdd('bgcolor', ($self->Position+1).".0",  ($self->Position+1).".0 lineend");
		$self->MyText->see(($self->Position+1).".0");
	      }
	    }
	    if ($self->Paused) {
	      usleep(200000);
	      $UNIVERSAL::clear->Listen(TimeOut => $self->DefaultTimeOut);
	    } else {
	      $char = $self->Say
		(
		 Offset => $self->Position,
		 Text => $self->MyDocData->Read($self->Position),
		);
	      if (exists $UNIVERSAL::clear->Config->CLIConfig->{'-W'}) {
		$UNIVERSAL::agent->Deregister;
		exit(0);
	      }
	    }
	    if ($char) {
	      print "c<<<$char>>>\n";

	      if ($char eq "b") {
		$self->CommandBackward();
	      } elsif ($char eq "f") {
		$self->CommandForward();
	      } elsif ($char =~ /g( ([0-9]+))?/) {
		$self->CommandGoto
		  (
		   Location => $2
		  );
	      } elsif ($char =~ /d( ([0-9\.]+))?/) {
		$self->CommandDuration
		  (
		   Duration => $2,
		  );
	      } elsif ($char =~ /v( ([0-9]+))?/) {
		$self->CommandVolume
		  (
		   Volume => $2,
		  );
	      } elsif ($char =~ /[sS](.+)?/) {
		$self->Search
		  (
		   Search => $2,
		  );
	      } elsif ($char eq "r") {
		$self->CommandRestartTTS();
	      } elsif ($char eq "p") {
		$self->CommandPause();
	      } elsif ($char eq "j") {
		$self->CommandJumpTo();
	      } elsif ($char eq "i") {
		$self->CommandIgnore();
	      }

	      if ($char =~ /[bfr]/) {
		$self->IncrementPosition;
	      }

	    } else {
	      if (! $self->Paused) {
		if (exists $conf->{'-r'}) {
		  $self->MyDocData->MarkRead($self->Position);
		}
		$self->IncrementPosition;
	      }
	    }
	  }
	  if (!$char) {
	    if ($self->ShouldBeReading) {
	      $self->HasBeenRead(1);
	    }

	    # if it's a liferea feed, we want to mark as read if we
	    # indeed read the whole contents, or if it was told to skip
	    # permanently

	    $self->SaveMetaData;
	    print "Finished\n";
	  }
	}
      }
    }
  } else {
    print ";; File not found\n";
  }
}

sub Say {
  my ($self,%args) = @_;
  my $i = 0;
  foreach my $text (@{$args{Text}}) {

    $self->PossiblyProdUser();
    if ($text) {
      $text =~ s/"//g;
      $text =~ s/\\//g;

      # print it to the screen
      if (! $self->MyText) {
	print wrap("", "", ($args{Offset}.") ".$text))."\n";
      }

      # if visualization is on, visualize it
      if (exists $UNIVERSAL::clear->Config->CLIConfig->{'-v'}) {
	$self->MyVisualizer->VisualizeText(Text => $text);
      }

      # print Dumper({Offset => $args{Offset}});
      $self->TurnClearToPage
	(
	 PageNo => $self->PageNos->[$args{Offset} + $i],
	);

      # say it over the TTS
      $UNIVERSAL::clear->MyTTS->Say
	(Text => $text);

      # wait until it is finished
      my $loop = 1;
      while ($loop) {
	my $result = $UNIVERSAL::clear->MyTTS->CheckForInput();
	if ($result eq "timeout") {
	  my $char = $self->CheckForUserInput;
	  if ($char) {
	    if ($char eq "q") {
	      $self->CommandQuit();
	    } elsif ($char =~ /^queue (.+)$/) {
	      push @{$UNIVERSAL::clear->Queue}, split /\s*,\s*/, $1;
	    } elsif ($char =~ /[bdfgijkpsv]/) {
	      print "Executing '$char'\n";
	      $UNIVERSAL::clear->MyTTS->ExecuteCommandTriggers
		(
		 Command => $char,
		);
	      return $char;
	    }
	  }
	} else {
	  $loop = 0;
	}
      }
    }
    ++$i;
  }
}

sub RecordToOggs {
  my ($self,%args) = @_;
  # let's read it now
  if (! -d $args{Dir}) {
    system "mkdirhier \"$args{Dir}\"";
  }
  my $i = 0;
  while (@{$args{Contents}}) {
    my @lines = splice @{$args{Contents}},0,30;
    my $fh = File::Temp->new;
    my $filename = $fh->filename;
    print $fh join("\n",@lines);
    # eventually add the ability to split this apart
    my $file = sprintf "%s%05i","clear",$i;
    ++$i;

    # lower the encoding quality, increase the number of sentences per ogg file, and clean the data more
    my $c = "cat \"$filename\" | text2wave -eval /etc/clear/fest.conf | oggenc - -o ".$args{Dir}."/$file.ogg";
    print "$c\n";
    system $c;
  }
}

sub LoadMetaData {
  my ($self) = (shift);
  my $command;
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

sub DESTROY {
  my ($self, %args) = @_;
  print Dumper({
		DestroyKeys => [keys %$self],
		Args => \%args,
	       });
  # $self->SaveMetaData;
  # $self->MyDocData("");
}

sub ExtractAbbrevs {
  my ($self,$txt) = (shift,shift);
  if ($txt =~ /(\S+)\s+(.*)/) {
    return ($1,$2);
  }
}

sub ExtractAbbrev {
  my ($self,$text) = (shift,shift);
  my $OUT;
  # really, use random number generation here
  open(OUT,">/tmp/clear3214324");
  print OUT $text;
  print "TEST\n";
  my %abbrev = map $self->ExtractAbbrevs($_), split /\n/,`cd /var/lib/myfrdcsa/codebases/internal/clear && java ExtractAbbrev /tmp/clear3214324`;
  print "TEST\n";
  print Dumper(%abbrev);
  print "TEST\n";
  sleep(100);
  print "TEST\n";
  return \%abbrev;
}

sub Review {
  my ($self) = (shift);
  print "Reviewing ".$self->OriginalFile . "...\n";
  $self->Parse;
  return unless $self->MyDocData;
  my $text;
  my $i = 0;
  my $end = $self->MyDocData->GetLatest;
  while ($i < $end) {
    if (defined($self->MyDocData->Data->[$i])
	&& $self->MyDocData->Data->[$i]->{Read}) {
      $text .= $self->MyDocData->Contents->[$i]."\n";
    }
    ++$i;
  }
  $i = 0;

  my %word_list = $UNIVERSAL::clear->Tagger->get_words( $text );
  my @words = sort {$word_list{$a} <=> $word_list{$b}} (keys %word_list);
  @words = splice(@words,0,25);
  my $score = 0;
  my $word;
  #   my $acronyms = $UNIVERSAL::clear->ExtractAbbrev->extract( $text );

  my $acronyms = $self->ExtractAbbrev( $text );
  my @tla = sort keys %$acronyms;

  while (@words) {
    $word = splice(@words,int(rand(scalar @words))-1,1);
    # lets go ahead, choose a random sentence which matches this word.
    $word =~ s/[^a-zA-Z0-9 ].*//;
    my @matches;
    foreach my $sentence (@{$self->MyDocData->Contents}) {
      if ($sentence =~ /\b$word\b/i) {
	push @matches, $sentence;
      }
    }
    if ($word =~ /^[a-zA-Z]+$/) {
      my $answer = $matches[int(rand(@matches))];
      my $question = $answer;
      $question =~ s/\b$word\b/_____/gi;
      print "\nQuestion $i\n";
      print wrap("", "", ($question))."\n> ";
      $response = <STDIN>;
      chomp $response;
      if (similarity($response,$word) > .75) {
	print "Correct! ($word)\n";
	++$score;
      } else {
	print "Incorrect! ($word)\n";
      }
    } else {
      print "?$word?\n";
    }
    ++$i;
  }
  print "Answered $score/".scalar @words." correct!\n";
}

# resume reading where we left off, record timing information on the readings

sub PossiblyProdUser {
  my ($self,%args) = @_;
  # if too  much time  has elapsed, check  whether the user  if paying
  # attention.   check  frequency should  increase  when  the user  is
  # expected to fall asleep or not pay attentions
  if (! (! exists $UNIVERSAL::clear->Config->CLIConfig->{"--prod"} or exists $UNIVERSAL::clear->Config->CLIConfig->{"-o"})) {
    if (! defined $UNIVERSAL::clear->LastVerified) {
      $UNIVERSAL::clear->LastVerified($self->CurrentTime);
    }
    if ($self->CurrentTime > $UNIVERSAL::clear->LastVerified + 5*60) {
      my $cnt = 0;
      my $char;
      do {
	$char = $self->ClearQueryUser(Message => "Are you paying attention?",
				      TimeOut => 5);
      } while (! $char and $cnt++ < 2);
      while (! $char) {
	sleep 1;
	$char = $self->CheckForUserInput;
      }
      $UNIVERSAL::clear->LastVerified($self->CurrentTime);
    }
  }
}

sub CurrentTime {
  my ($self,%args) = @_;
  my $time = `date "+%s"`;
  return $time;
}

sub ClearQueryUser {
  my ($self,%args) = @_;
  my $text = $args{Message};
  if ($text) {
    $text =~ s/"//g;
    $text =~ s/\\//g;
    my $command = "(SayText \"$text\")";
    print wrap("", "", "Query: ".$text)."\n";
    $UNIVERSAL::clear->MyTTS->Say
      (Text => $text);
    # wait until it is finished
    my $loop = 1;
    while ($loop) {
      my $result = $UNIVERSAL::clear->MyTTS->CheckForInput();
      if ($result eq "timeout") {
	my $char = $self->CheckForUserInput;
	if ($char) {
	  return $char;
	}
      } else {
	$loop = 0;
      }
    }
  }
}

sub OpenInEditor {
  my ($self,%args) = @_;
  if (! defined $self->Editor) {
    my $handlers =
      {
       "PDF" => "xpdf FILE &",
       "Microsoft Office Document" => "openoffice FILE &",
       "PostScript" => "gv FILE &",
       "English text" => "emacsclient FILE",
       "exported SGML document text" => "emacsclient FILE",
       "HTML document text" => "mozilla -remote 'openUrl(FILE)'",
      };
    my $file = $self->QuotedOriginalFile;
    if (defined $self->FileType) {
      $command = "";
      my $success = 0;
      foreach my $regex (keys %$handlers) {
	if ($self->FileType =~ /$regex/) {
	  $command = $handlers->{$regex};
	  $success = 1;
	  last;
	}
      }
      if ($success) {
	$command =~ s/FILE/$file/;
	system $command;
	$self->Editor(1);
      } else {
	print "No handler for file type <".$self->FileType.">!\n";
      }
    } else {
      print "Unknown file type!\n";
    }
  }
}

sub CommandPause {
  my ($self,%args) = @_;
  my $tmp;
  if (! $UNIVERSAL::clear->Config->CLIConfig->{"--no-gui"}) {
    $self->Paused(! $self->Paused);
    print "Toggling pause\n";

    # change the button properties
    # print Dumper({Readers => $UNIVERSAL::clear->MyGUI->Readers});
    my $item = $UNIVERSAL::clear->MyGUI->Readers->{$self->ReadListID};
    print SeeDumper
      ({
	Ref => ref($item),
	Keys => [keys %$item],
	ReadListID => $self->ReadListID,
       });
    if ($self->Paused) {
      $UNIVERSAL::clear->MyGUI->Readers->Contents->{$self->ReadListID}->MyTabManager->Tabs->{Display}->Buttons->{Pause}->configure(-background => "red");
      $UNIVERSAL::clear->MyGUI->Readers->Contents->{$self->ReadListID}->MyTabManager->Tabs->{Display}->Buttons->{Pause}->configure(-highlightcolor => "red");
    } else {
      $UNIVERSAL::clear->MyGUI->Readers->Contents->{$self->ReadListID}->MyTabManager->Tabs->{Display}->Buttons->{Pause}->configure(-background => "lightgray");
      # $UNIVERSAL::clear->MyGUI->Readers->Contents->{$self->ReadListID}->MyTabManager->Tabs->{Display}->Buttons->{Pause}->configure(-highlightcolor => "lightgray");
    }
  } else {
    do {
      $tmp = $self->CheckForUserInput;
    } while ((defined $tmp and $tmp !~ /p/) and usleep(200000));
  }
}

sub CommandRestartTTS {
  my ($self,%args) = @_;
  $UNIVERSAL::clear->MyTTS->RestartTTS;
}

sub CommandJumpTo {
  my ($self,%args) = @_;
  # write some code  to subset select where to  jump to in
  # the readlist
  if ($UNIVERSAL::clear->MyReadList->JumpTo) {
    $self->SaveMetaData;
    # print "Skipping ".$self->OriginalFile . "\n";
    $self->Stop(1);
  }
}

sub CommandIgnore {
  my ($self,%args) = @_;
  $self->HasBeenRead(2);
  $self->SaveMetaData;
  print "Ignoring ".$self->OriginalFile . "\n";
  $self->Stop(1);
}

sub CommandSearch {
  my ($self,%args) = @_;
  my $search;
  if (defined $args{Search}) {
    $search = $args{Search};
  } else {
    $search = <STDIN>;
    do {
      print "Please enter the search phrase to jump to:\n";
      $search = <STDIN>;
      chomp $search;
      $search =~ s/^\s*//;
      $search =~ s/\s*$//;
    } while (! $search);
  }

  # now search for this term
  print "Searching...\n";
  my $k = $self->Position;
  my $l = -1;
  while ($k < scalar @{$self->MyDocData->Contents} and
	 $l < 0) {
    my $line = $self->MyDocData->Contents->[$k];
    if ($line =~ /$search/i) {
      $l = $k;
    }
    ++$k;
  }
  if ($l >= 0) {
    $self->SetPosition($l);
  }
  print "Done.\n";
}

sub CommandBackward {
  my ($self,%args) = @_;
  $self->DecrementPosition;
}

sub CommandForward {
  my ($self,%args) = @_;
  $self->IncrementPosition;
}

sub CommandGoto {
  my ($self,%args) = @_;
  if ($args{Relative}) {
    my $r = $args{Relative};
    my $start = 0;
    my $end = $self->MyDocData->ContentsSize;
    my $newpos = $self->Position;
    if ($r eq "beginning") {
      $newpos = $start;
    } elsif ($r eq "previous 10") {
      $newpos = Max($self->Position - 10, $start)
    } elsif ($r eq "previous line") {
      $newpos = Max($self->Position - 1, $end)
    } elsif ($r eq "next line") {
      $newpos = Min($self->Position + 1, $end)
    } elsif ($r eq "next 10") {
      $newpos = Max($self->Position + 10, $end)
    } elsif ($r eq "ending") {
      $newpos = $end;
    }
    $self->SetPosition($newpos);
    return;
  }
  if (! $UNIVERSAL::clear->Config->CLIConfig->{"--no-gui"}) {
    # pop up a window with
    my $position;
    my $continue = 1;
    while ($continue) {
      my $res = QueryUser2
	(
	 Message => "Please enter the sentence number: ",
	);
      if ($res->{Cancel}) {
	$continue = 0;
      } else {
	$position = $res->{Value};
	chomp $position;
	if ($position =~ /[0-9]+/ and $position >= 0 and $position < scalar @{$self->MyDocData->Contents}) {
	  $self->SetPosition($position);
	  $continue = 0;
	}
      }
    }
  } else {
    if (! defined $args{Location}) {
      do {
	print "Please enter the sentence number\n";
	my $input = <STDIN>;
	$self->SetPosition($input);
	chomp $self->Position;
      } while (!($self->Position =~ /[0-9]+/ and
		 $self->Position >= 0 and
		 $self->Position < scalar @{$self->MyDocData->Contents}));
    } else {
      my $j = $args{Location};
      if ($j =~ /[0-9]+/ and
	  $j >= 0 and
	  $j < scalar @{$self->MyDocData->Contents}) {
	$self->SetPosition($j);
      }
    }
  }
}

sub CommandDuration {
  my ($self,%args) = @_;
  if (! defined $args{Duration}) {
    my $j = <STDIN>;
    do {
      print "Please enter the new duration, (default 1.0) (to control speed)\n";
      $j = <STDIN>;
      chomp $j;
    } while (!($j =~ /[0-9\.]+/ and
	       $j >= 0));
    $UNIVERSAL::clear->MyTTS->ChangeTTSSpeed(Duration => $j);
  } else {
    $UNIVERSAL::clear->MyTTS->ChangeTTSSpeed(Duration => $args{Duration});
  }
}

sub CommandVolume {
  my ($self,%args) = @_;
  if (! defined $args{Volume}) {
    my $j = <STDIN>;
    do {
      print "Please enter the new volume (1-100)\n";
      $j = <STDIN>;
      chomp $j;
    } while (!($j =~ /[0-9]+/ and
	       $j >= 0 and
	       $j <= 100));
    $UNIVERSAL::clear->MyTTS->ChangeVolume(Volume => $j);
  } else {
    $UNIVERSAL::clear->MyTTS->ChangeVolume(Volume => $args{Volume});
  }
}

sub CommandActivate {
  my ($self,%args) = @_;
  $UNIVERSAL::clear->MyGUI->ActiveReadList($self->ReadListID);
}

sub CommandQuit {
  my ($self,%args) = @_;
  $self->SaveMetaData;
  exit(0);
}

sub IncrementPosition {
  my ($self,%args) = @_;
  $self->SetPosition($self->Position + 1);
}

sub DecrementPosition {
  my ($self,%args) = @_;
  $self->SetPosition($self->Position - 1);
}

sub SetPosition {
  my ($self,$position) = @_;
  if ($self->MyText and $self->Position) {
    $self->MyText->tagRemove('bgcolor', ($self->Position + 1).".0",  ($self->Position + 1).".0 lineend");
  }
  $self->Position($position);
  if ($self->MyText) {
    $self->MyText->tagAdd('bgcolor', ($self->Position + 1).".0",  ($self->Position + 1).".0 lineend");
    $self->MyText->see(($self->Position + 1).".0 lineend");
  }
}

sub ShouldBeReading {
  my ($self,%args) = @_;
  return $UNIVERSAL::clear->MyGUI->ActiveReadList == $self->ReadListID;
}

sub ComputeOrRecomputePageNumbers {
  my ($self,%args) = @_;
  $self->ComputePageNumbers;
  if (exists $UNIVERSAL::clear->Config->CLIConfig->{'--add-page-markers'}) {
    if ($self->PageNos->[-1] == 0) {
      my $data = \@{$self->MyDocData->Data};
      $self->DoParse();
      $self->MyDocData->Data($data);
      $self->SaveMetaData;
      $self->ComputePageNumbers;
    }
  }
}

sub ComputePageNumbers {
  my ($self,%args) = @_;
  my $pageno = 0;
  my $i;
  # print Dumper({ContentsSize => $self->MyDocData->ContentsSize});
  foreach my $i (1 .. $self->MyDocData->ContentsSize) {
    my @items = $self->MyDocData->Contents->[$i] =~ /(.*?)()(.*?)/sg;
    my $newpages = (scalar @items) / 3;
    $pageno += $newpages;
    $self->PageNos->[$i] = $pageno;
  }
  # print Dumper([$self->PageNos]);
}

sub TurnClearToPage {
  my ($self,%args) = @_;
  my $debugturncleartopage = 0;
  print Dumper({
		PageNo => $args{PageNo},
		CurrentPage => $self->CurrentPage,
	       }) if $debugturncleartopage;
  if (! scalar @{$self->PageNos}) {
    # compute the page numbers for the document
    $self->ComputeOrRecomputePageNumbers();
  }
  print Dumper({
		PageNo0 => $args{PageNo},
		CurrentPage => $self->CurrentPage,
	       }) if $debugturncleartopage;
  if (defined $self->PageNos->[$args{PageNo}]) {
    print Dumper
      ({
	PageNo0a => $args{PageNo},
	CurrentPage => $self->CurrentPage,
	Misc => $self->PageNos->[$args{PageNo}],
       }) if $debugturncleartopage;
    if ($self->CurrentPage ne $args{PageNo}) {
      $self->CheckWhetherCurrentPageIsFinishedAndIfSoAssertItIsRead();
      print Dumper({PageNo1 => $args{PageNo}}) if $debugturncleartopage;
      $self->CurrentPage($args{PageNo});
      TurnToPage
	(
	 PageNo => $args{PageNo},
	 File => $self->ChasedOriginalFile,
	);
      # eventually implement a query agent functionality here
      print Dumper({
		    PageNo2 => $args{PageNo},
		    CurrentPage => $self->CurrentPage,
		   }) if $debugturncleartopage;
      $self->CurrentPage($args{PageNo});
    }
  }
  print Dumper({
		PageNo3 => $args{PageNo},
		CurrentPage => $self->CurrentPage,
	       }) if $debugturncleartopage;
}

sub CheckWhetherCurrentPageIsFinishedAndIfSoAssertItIsRead {
  my ($self,%args) = @_;
  my $existsunreadsentence = 0;
  foreach my $i (1 .. $self->MyDocData->ContentsSize) {
    if ($self->PageNos->[$i] == $self->CurrentPage) {
      if (! defined $self->MyDocData->Data->[$i]) {
	$existsunreadsentence = 1;
	break;
      }
    }
  }
  if (! $existsunreadsentence) {
    MarkPageAsRead
      (
       PageNo => $self->CurrentPage,
       File => $self->ChasedOriginalFile,
      );

    my $docid = 1;
    my $epoch = `date "+%s"`;
    chomp $epoch;

    my $pageno = $self->CurrentPage || 0;

    # KBS2::Client
    my $res1 = $UNIVERSAL::agent->QueryAgent
      (
       Receiver => "KBS2",
       Data => {
		_DoNotLog => 1,
		Command => 'assert',
		Formula => ['r',['d',$docid],['p',$pageno],['to',$epoch]],
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

1;
