package Clear::Mod::Liferea;

# this could also be useful for coauthor

use Manager::Dialog qw(Approve);

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyTagger MyGoogleImages /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyTagger
    (Lingua::EN::Tagger->new(stem => 0));
  # $self->MyGoogleImages
  # (System::WWW::GoogleImages->new());
}

sub LoadFeeds {
  my ($self,%args) = @_;
}

sub Top {
  my $c = shift;
  return splice(@_,0,$c);
}

1;
