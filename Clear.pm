package Clear;

use BOSS::Config;
use Clear::Mod::Reader;
use Clear::Mod::GUI;
use Clear::ReadList;
use Clear::TTS::ALL;
use Clear::TTS::Festival;
use Manager::Dialog qw (Message ApproveCommands);
use MyFRDCSA;
use PerlLib::SwissArmyKnife;
use PerlLib::ToText;

use Data::Dumper;
use Lingua::EN::Tagger;
use Net::Telnet;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Config MetaDataFile VirtualReadList DefaultReadList
        MyReadLists Agent Tagger SystemDir WebsiteDir ScriptsDir
        LastCommand LastVerified Queue Mode MyTTS MyToText MyGUI
        IDCounter /

  ];

my $seen = 0;

sub init {
  my ($self,%args) = @_;
  $specification = "
	--no-gui		Run without the GUI

	-c			Clean items (remove all related voy files)
	-d			Run as a daemon
	-i			Run interactively
        --next			Follow 'next' tags
        --body			Use Body Text Extractor to discard nonsense on websites
        -p			Print default readlist
	-q			Quiz on items

	--add-page-markers	Reindex a voy adding pages turn markers

	-r			Read items
	-o <dir>		Output to ogg files in dir
	-e			Open the document in an appropriate editor

	-s [<depth>]		Enable intelligent spidering for urls
	-v			Visualize (show pictures of key concepts from web)

        -A <ext>		Accept extensions (comma-separated)
        -R <ext>		Reject extensions (comma-separated)
	-u [<host> <port>]	Run as a UniLang agent
	-W [<delay>]		Exit as soon as possible (with optional delay)

	-l			List readlists
	--add <readlist>	Add items to readlist
	--list <readlist>	List items in readlist
	--edit <readlist>	Edit the readlist (order, remove, etc)
	--prereqs <readlist>	Reorder the readlist according to assumed prerequisites
	--suggest-prereqs <rl>	Suggest additional materials to add to readlist

	--tts <TTS>		Use TTS (Either Festival or ALL at time of writing)

        -f <type>		Force type
	--list-types		List all available types

	--test-load		Test loading of multiple documents:

	--dep			Enable forced dependencies
	--prod			Ask the user if they are paying attention
	<items>...		Items (readlists, URIs, packages, ...)
";
  $UNIVERSAL::agent->DoNotDaemonize(1);
  $self->Config(BOSS::Config->new
		(Spec => $specification,
		 ConfFile => ""));
  $UNIVERSAL::systemdir = ConcatDir(Dir("internal codebases"),"clear");

  my $conf = $self->Config->CLIConfig;
  if (! exists $conf->{'--no-gui'}) {
    $self->MyGUI
      (Clear::Mod::GUI->new
       (Clear => $self));
  }
  if (exists $conf->{'-u'}) {
    $UNIVERSAL::agent->Register(Host => defined $conf->{-u}->{'<host>'} ? $conf->{-u}->{'<host>'} : "localhost",
				Port => defined $conf->{-u}->{'<port>'} ? $conf->{-u}->{'<port>'} : "9000");
  }
  $self->IDCounter(0);
  $self->MyReadLists({});
  $self->MyToText(PerlLib::ToText->new);
  $self->LastCommand([]);
  $self->Queue([]);
  $self->Tagger(Lingua::EN::Tagger->new(stem => 0));
  $self->SystemDir
    (ChooseFirst
     (
      Items => [
		"/var/lib/clear",
		ConcatDir(Dir("internal codebases"),"clear"),
	       ],
     ));
  $self->DefaultReadList
    (ConcatDir($self->SystemDir,"lists","default.rl"));
  #   $self->WebsiteDir
  #     (ConcatDir($self->SystemDir,"websites"));
  $self->WebsiteDir
    ("/var/lib/myfrdcsa/codebases/internal/digilib/data/collections/clear");
  $self->ScriptsDir
    (ConcatDir($self->SystemDir,"scripts"));
  if ((! $conf->{'--tts'}) or $conf->{'--tts'} eq "Festival") {
    $self->MyTTS
      (
       Clear::TTS::Festival->new
       (SystemDir => $self->SystemDir),
      );
  } elsif ($conf->{'--tts'} eq "ALL") {
    $self->MyTTS
      (
       Clear::TTS::ALL->new(),
      );
  }
  if ($conf->{'--list-types'}) {
    $self->MyToText->ListTypes;
  }
  $self->Mode("startup");
}

sub Execute {
  my ($self,%args) = @_;

  my $conf = $self->Config->CLIConfig;
  if (! exists $conf->{'--no-gui'}) {
    $self->MyGUI->Execute;
  }

  $self->MetaDataFile("metadata" || "");
  if (exists $conf->{'-p'}) {
    my $text = read_file($self->DefaultReadList);
    print $text."\n\n";
  }

  # load virtual readlist
  if (exists($conf->{'-a'}) or exists($conf->{'-A'})) {
    $self->VirtualReadList
      ([$conf->{'-a'} || $self->DefaultReadList]);
  } else {
    $self->VirtualReadList
      (($conf->{'<items>'} and scalar @{$conf->{'<items>'}})
       ? $conf->{'<items>'}
       : [$self->DefaultReadList]);
  }
  if (exists($conf->{'-a'}) or exists($conf->{'-A'})) {
    my @items;
    if (scalar@{$conf->{'-a'}}) {
      @items = @{$conf->{'-a'}};
    } else {
      @items = @{$conf->{'<items>'}};
    }
    # add items to readlist
    my $OUT;
    open(OUT, ">>".$self->VirtualReadList->[0]) or
      die "Cannot open readlist <".$self->VirtualReadList->[0].">\n";
    print OUT (join "\n",@items)."\n";
    close(OUT);
  } else {
    if (exists $self->Config->CLIConfig->{'-r'}) {
      $self->SwitchMode
	(
	 Mode => "read",
	);
    }
    # just sit in a holding pattern, listening for commands to read items.
    # while (1) {
    while (scalar @{$self->VirtualReadList} or
    	   scalar @{$self->Queue} or
    	   exists $conf->{-u}) {

      if (scalar @{$self->VirtualReadList} or
	  scalar @{$self->Queue}) {
	print Dumper
	  ({
	    VirtualReadList => $self->VirtualReadList,
	    Queue => $self->Queue,
	   }) if 0;
      }
      if (scalar @{$self->VirtualReadList}) {
	# FIRST ITERATION
	print Dumper({VirtualReadList => $self->VirtualReadList});
	$self->IDCounter($self->IDCounter + 1);
	my $id = $self->IDCounter;
	$self->MyReadLists->{$id} =
	  (Clear::ReadList->new
	   (
	    ReadList => $self->VirtualReadList,
	    Mode => $self->Mode,
	    ID => $id,
	   ));
	$self->MyGUI->AddReader(ReadList => $self->MyReadLists->{$id});
	$self->MyReadLists->{$id}->ProcessReadList;
	$self->MyGUI->UpdateTabName(ID => $id);
	print Dumper({ReadList => $self->MyReadLists->{$id}});
	if ($self->MyGUI) {
	  $self->MyGUI->Readers->Contents->{$self->MyGUI->ActiveReadList}->
	    MyTabManager->Tabs->{ReadList}->Redisplay();
	}
	$self->MyReadLists->{$id}->Process;

	$self->VirtualReadList($self->Queue);
	$self->Queue([]);
      } elsif (scalar @{$self->Queue}) {
	$self->VirtualReadList($self->Queue);
	$self->Queue([]);
      # } elsif ($self->MyGUI and
      # 	       defined $self->MyGUI->ActiveReadList
      # 	       # and
      # 	       # scalar $self->MyGUI->Readers->Contents->{$self->MyGUI->ActiveReadList}->
      # 	       # MyReadList->ListUnreadDocuments
      # 	      ) {
      # 	$self->MyGUI->Readers->Contents->{$self->MyGUI->ActiveReadList}->
      # 	  MyTabManager->Tabs->{ReadList}->Redisplay();
      # 	$self->MyGUI->Readers->Contents->{$self->MyGUI->ActiveReadList}->MyReadList->Process;
      } else {
	$UNIVERSAL::clear->Listen(TimeOut => 0.05);
	if (scalar @{$UNIVERSAL::clear->LastCommand}) {
	  my $res1 = shift @{$UNIVERSAL::clear->LastCommand};
	  my $it = $res1->{Command};
	  my $sender = $res1->{Sender};
	  print "RESPONSE: <$it>\n";
	  if ($it =~ /^queue (.+)$/) {
	    # FIXME: this should work on CSV style CSV, not just comma
	    # separated, i.e. it should quote commas that are part of
	    # the filename.  Moreover the emacs commands that issue
	    # the Queue should handle that CSV format as well.
	    push @{$self->Queue}, $1; # split /\s*,\s*/, $1;
	  } elsif ($it =~ /^(quit|exit)$/i) {
	    $UNIVERSAL::agent->Deregister;
	    exit(0);
	  }
	}
      }
      print Dumper
	({
	  VirtualReadList => $self->VirtualReadList,
	  Queue => $self->Queue,
	 }) if 0;
    }
  }
}

# sub LoadMetaData {
#   my ($self,%args) = @_;
#   if (-f $self->MetaDataFile) {
#     my $command = "cat ".$self->MetaDataFile;
#     $self->MyReadList(eval `$command`);
#   } else {
#     $self->MyReadList
#       (Clear::ReadList->new
#        (ReadList => $self->VirtualReadList));
#   }
# }

# sub SaveMetaData {
#   my ($self,%args) = @_;
#   if (defined $self->MyReadList) {
#     my $OUT;
#     open (OUT, ">".$self->MetaDataFile) || die "Cannot open MetaDataFile ".$self->MetaDataFile .
#       "for opening.\n";
#     print OUT Dumper($self->MyReadList);
#     close (OUT);
#   }
# }

sub ProcessCommand {
  my ($self,$command) = @_;
  push @{$self->LastCommand},
    {
     Command => $command,
     Sender => $sender,
    };
}

sub Listen {
  my ($self,%args) = @_;
  my $conf = $self->Config->CLIConfig;
  if (defined $self->MyGUI) {
    $self->MyGUI->Listen
      (
       TimeOut => $args{TimeOut},
      );
  }
  if (exists $conf->{-u}) {
    $UNIVERSAL::agent->Listen
      (
       TimeOut => $args{TimeOut},
      );
  }
}

sub CurrentDoc {
  my ($self,%args) = @_;
  print SeeDumper({ActiveReadList => $self->MyGUI->ActiveReadList});
  return $self->MyGUI->Readers->Contents->{$self->MyGUI->ActiveReadList}->MyReadList->CurrentDoc;
}

sub SwitchMode {
  my ($self,%args) = @_;
  if ($args{Mode} eq "read" and $self->Mode ne "read") {
    $self->Mode("read");
    $self->MyTTS->StartTTS;
  }
}

sub DESTROY {
  my ($self,%args) = @_;
  $self->SaveMetaData;
}

1;

=head1 NAME

Clear -  Interface to  what the person  is reading, to  determine what
they are reading, etc.

=head1 SYNOPSIS

    use Verber;

=head1 ABSTRACT

Hello, I'll  be your AI teacher  for today.  I'm not  perfect, but I'm
certainly better than nothing.

This system  not only  assists with the  passive determination  of the
user's reading content, based on  various sources (for instance, if it
is reading  documents to the person,  or if it is  using eye tracking,
etc.),  but also  assists with  integrating with  the  larger planning
issues.

The  basic idea  behind this  implementation is  to load  any previous
metadata  we want  to be  able eventually  to interface  with planning
directives,  such as "learn  this".  Obviously  we would  benefit from
language describing learning preferences, etc, of the student.

For now, we need to simply have the following functionality to be able
to deploy clear to my purpose.

Start with a readlist of files to be learned.  (You know, critic would
be useful.  We could apply machine learning to find out which kinds of
documents the user likes by comparison with previous reading habits.)

Now, simply  create document instances  for all of these.   Then, call
the function,  ResumeReading.  This finds the last  document which was
being read, if any, and starts reading from the point in the document.
If no  documents have been read, it  selects the next one  on the list
and converts it, and then begins reading it at the sentence level.  So
we only have  to take care of writing the  converter, and the sentence
level representation.

Of  course, clear should  also handle  manuals for  open source
materials, like the emacs manual.

By integrating testing we will really have an operational product.

=head1 DESCRIPTION

To find how to use this module in detail, see L<Encode>.

=head1 SEE ALSO

L<Encode>

=cut
