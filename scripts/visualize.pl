#!/usr/bin/perl -w

use BOSS::Config;
use Clear::Mod::Visualize::Engine::Visualize2::OpenGL;
use PerlLib::SwissArmyKnife;

$specification = q(
	-s <search>	Search for this topic
	-r		Record a movie file
	-f		Force Fullscreen
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
$UNIVERSAL::conf = $config->CLIConfig;
$UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/internal/clear";

my $opengl = Clear::Mod::Visualize::Engine::Visualize2::OpenGL->new
  (
  );

$opengl->Execute
  (
   Search => $UNIVERSAL::conf->{'-s'},
   ExportVideo => exists $UNIVERSAL::conf->{'-r'},
   FullScreen => exists $UNIVERSAL::conf->{'-f'},
  );
