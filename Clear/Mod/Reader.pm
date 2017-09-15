package Clear::Mod::Reader;

use Clear::Mod::Reader::TabManager;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyGUI MyReadList MyTabManager MyReaderWindow /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyGUI($args{GUI});
  $self->MyReaderWindow($args{ReaderWindow});
  $self->MyTabManager
    (Clear::Mod::Reader::TabManager->new(ReadListID => $args{ReadListID}));
  $self->MyReadList($args{ReadList});

}

sub Execute {
  my ($self,%args) = @_;
  $self->MyTabManager->Execute
    (
     ReaderWindow => $self->MyReaderWindow,
    );
}

1;
