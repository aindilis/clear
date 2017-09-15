package Clear::Mod::Visualize;

# base class for Visualization engines

use Capability::NER;


use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Name Engine /

  ];

sub init {
  my ($self,%args) = @_;
  my $name = $args{EngineName} || "Visualize2";
  $self->Name($name);
  require "Clear/Mod/Visualize/Engine/$name.pm";
  $self->Engine("Clear::Mod::Visualize::Engine::$name"->new());
  # $self->StartServer;
  # $self->StartClient;
}

sub StartServer {
  my ($self,%args) = @_;
  # $self->Engine->StartServer;
}

sub StartClient {
  my ($self,%args) = @_;
  $self->Engine->StartClient;
}

sub VisualizeText {
  my ($self,%args) = @_;
  return $self->Engine->VisualizeText(%args);
}

1;

