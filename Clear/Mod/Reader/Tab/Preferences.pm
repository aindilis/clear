package Clear::Mod::Reader::Tab::Preferences;

# have an open display here, and do fades, etc.

use base qw(Clear::Mod::Reader::Tab);

use Dashboard::Tab::Launcher::Program;
use PerlLib::SwissArmyKnife;
use Rival::PPI::_Util;
use UniLang::Util::AgentRegistry;

use Data::Dumper;
use PPI::Document;
use Tk::Pane;
use Tk::Scrollbar;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyFrame AgentRegistry /

  ];

sub init {
  my ($self,%args) = @_;
  $self->MyFrame($args{Frame});
}

sub Execute {
  my ($self,%args) = @_;
  my $specification;
  my $file = "/var/lib/myfrdcsa/codebases/internal/clear/Clear.pm";
  if (-f $file) {
    $res2 = $self->ExtractSpecificationInformation
      (
       File => $file,
      );
  }
  if ($res2->{Success}) {
    # okay add this to the system
    # $specifications->{$res2->{Result}->{InvocationCommand}}->{Specification} = $res2->{Result}->{Specification};
    $specification = $res2->{Result}->{Specification};
    # okay now attempt to do something with this
  }

  my $scrollframe = $self->MyFrame->Scrolled
    (
     'Frame',
     # -background => 'white',
     -scrollbars => 'e',
    )->pack(-expand => 1, -fill => "both");

#   my $program = Dashboard::Tab::Launcher::Program->new
#     (
#      NoTopLevel => 1,
#      # Verbose => 1,
#      MainWindow => $scrollframe,
#      # InvocationCommand => "/usr/bin/cla",
#      Program => "Clear",
#      Specification => $specification,
#     );

  $self->MyFrame->pack();
}

sub ExtractSpecificationInformation {
  my ($self,%args) = @_;
  my $c = read_file($args{File});
  if ($c =~ /\$specification/) {
    # print "<".$args{File}.">\n";
    my $doc = PPI::Document->new($args{File});
    # my $dumper = PPI::Dumper->new($doc);
    # $dumper->print;
    my $nodes = $doc->find
      (
       sub { $_[1]->isa('PPI::Statement') and
	       [$_[1]->children]->[0]->isa('PPI::Token::Symbol') and
		 [$_[1]->children]->[0]->symbol eq '$specification' }
      );
    foreach my $node (@$nodes) {
      my $res = ProcessVariables(Node => $node);
      if ($res->{Success}) {
	return {
		Success => 1,
		Result => {
			   Specification => NodeSerialize(Node => $res->{Result}->{RHSs}->[0]),
			   InvocationCommand => $args{File},
			  },
	       };
      }
    }
    return {
	    Success => 0,
	   };
  }
  return {
	  Success => 0,
	 };
}

sub ProcessSpecification {
  my ($self,%args) = @_;
  my $program = Dashboard::Tab::Launcher::Program->new
    (
     MainWindow => $self->MyFrame,
     InvocationCommand => "",
     Program => "Clear",
     Specifications => $self->Specifications,
    );
}

1;



