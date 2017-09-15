package Clear::Mod::Reader::Tab::ReadList;

use Digi::Collection::SourceManager;
use Digi::Collection;
use Manager::Dialog qw(Choose SubsetSelect);
use PerlLib::SwissArmyKnife;

use Tk::FileSelect;

use base qw(Clear::Mod::Reader::Tab);

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyFrame MyText Items MySourceManager MyCollection ReadListID /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyFrame($args{Frame});
  $self->ReadListID($args{ReadListID});
}

sub Execute {
  my ($self,%args) = @_;
  my $itemsframe = $self->MyFrame->Frame();
  $self->Items
    ({
      "Remove All Items" => {
			     Type => "button",
			    },
      "Add Item" => {
		     Type => "button",
		     Sub => sub {$self->SelectFileToRead()},
		    },
      "Update Index" => {
			 Type => "button",
			},
      "Add Collection" => {
			   Type => "button",
			  },
      "File Search" => {
			Type => "search",
			Sub => sub {
			  $self->FileSearch3
			    (
			     Search => ${$self->Items->{"File Search"}->{EntryText}},
			    );
			},
		       },
      "Fulltext Search" => {
			    Type => "search",
			   },
      "Save ReadList" => {
			  Type => "search",
			 },
      "Open ReadList" => {
			  Type => "search",
			 },
     });

  foreach my $key (sort keys %{$self->Items}) {
    if ($self->Items->{$key}->{Type} eq "button") {
      $itemsframe->Button
	(
	 -text => $key,
	 -command => $self->Items->{$key}->{Sub},
	)->pack(-side => 'right');
    } elsif ($self->Items->{$key}->{Type} eq "search") {
      my $var = "";
      my $searchframe = $itemsframe->Frame
	(
	 -borderwidth => 3,
	 -relief => "sunken",
	);
      $searchframe->Button
	(
	 -text => $key,
	 -command => $self->Items->{$key}->{Sub},
	)->pack(-side => 'right');
      $self->Items->{$key}->{EntryText} = \$var;
      $searchframe->Entry
	(
	 -textvariable => $self->Items->{$key}->{EntryText},
	)->pack(-side => 'right');
      $searchframe->pack(-side => 'right');
    }
  }

  $itemsframe->pack;

  my $textframe = $self->MyFrame->Frame();
  $self->MyText
    ($textframe->Text
     (
      -width => 120,
      -height => 30,
     ));
  my $scrollbar = $textframe->Scrollbar
    ();
  $scrollbar->pack(-side => "right", -fill => "y");
  $self->MyText->pack(-side => "left", # -fill => "both", -expand => 1
		     );
  $scrollbar->configure
    (
     -command => ['yview', $self->MyText],
    );
  $self->MyText->configure
    (
     -yscrollcommand => ['set', $scrollbar],
    );
  $textframe->pack(-fill => "both", -expand => 1);
  $self->MyFrame->pack();
}

sub FileSearch {
  my ($self,%args) = @_;
  $UNIVERSAL::managerdialogtkwindow = $UNIVERSAL::clear->MyGUI->Readers->Contents->{$self->ReadListID}->MyMainWindow;
  print Dumper(\%args);
  my $command = "digi -s ".shell_quote($args{Search});
  my $res = `$command`;
  # now we have to use subset select here
  my @set = split /\n/, $res;
  my @res = SubsetSelect
    (
     Set => \@set,
     Selection => {},
    );
  # add each file to the reading list
  foreach my $file (@res) {
    $self->QueueFile
      (
       File => $file,
      );
  }
}

sub FileSearch2 {
  my ($self,%args) = @_;
  $UNIVERSAL::managerdialogtkwindow = $UNIVERSAL::clear->MyGUI->Readers->Contents->{$self->ReadListID}->MyMainWindow;
  print Dumper(\%args);
  if (! defined $self->MySourceManager) {
    $self->MySourceManager
      (Digi::Collection::SourceManager->new
       (
	SourceDir => "/var/lib/myfrdcsa/codebases/internal/digilib/Digi/Collection/Source",
       ));
  }
  my $res = $self->MySourceManager->Search
    (Search => $args{Search});

  my @set;
  foreach my $item (@$res) {
    push @set, $item->Filename;
  }

  # now we have to use subset select here
  my @res = SubsetSelect
    (
     Set => \@set,
     Selection => {},
    );

  # add each file to the reading list
  foreach my $file (@res) {
    print "Queuing file $file\n";
    $self->QueueFile
      (
       File => $file,
      );
  }
}

sub FileSearch3 {
  my ($self,%args) = @_;
  $UNIVERSAL::managerdialogtkwindow = $UNIVERSAL::clear->MyGUI->Readers->Contents->{$self->ReadListID}->MyMainWindow;
  if (! defined $self->MyCollection) {
    $self->MyCollection
      (Digi::Collection->new
       (
	SourceDir => "/var/lib/myfrdcsa/codebases/internal/digilib/Digi/Collection/Source",
       )
      );
  }
  my $res = $self->MyCollection->Search
    (Search => $args{Search});
  my @items = ("Cancel");
  foreach my $entry (@$res) {
    if (defined $entry->Filename) {
      push @items, $entry->Filename;
    }
  }
  my @files;
  @files = Choose(@items);
  foreach my $file (@files) {
    if ($file eq "Cancel") {
      last;
    }
    $self->QueueFile
      (
       File => $file,
      );
  }
}

sub SelectFileToRead {
  my ($self,%args) = @_;
  my $dir = `pwd`;
  chomp $dir;
  my $FSref = $UNIVERSAL::clear->MyGUI->Readers->Contents->{$self->ReadListID}->MyMainWindow->FileSelect
    (-directory => $dir);
  $file = $FSref->Show;
  $self->QueueFile
    (
     File => $file,
    );
}

sub QueueFile {
  my ($self,%args) = @_;
  my $file = $args{File};
  if ($file ne "" and -f $file) {
    # print "$file\n";
    $UNIVERSAL::clear->SwitchMode
      (
       Mode => "read",
      );
    push @{$UNIVERSAL::clear->Queue}, $file;
  }
  $self->Redisplay;
}

sub Redisplay {
  my ($self,%args) = @_;
  # clear everything and show current playlist
  $self->MyText->Contents("");
  foreach my $document (keys %{$UNIVERSAL::clear->MyReadLists->{$self->ReadListID}->Documents}) {
    $self->MyText->insert("end", "$document\n");
  }
}

1;
