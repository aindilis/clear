#!/usr/bin/perl -w

# in the future take into account things like content, but for now, just put shorted docs first

use BOSS::Config;
use PerlLib::SwissArmyKnife;

use Error qw(:try);
use File::Stat;
use PDF;

$specification = q(
	-r <readlist>		Reading list to process
	--aggregate <dir>	Aggregate the files into dir
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
# $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/system";
my $c = read_file($conf->{'-r'});
my @files;
foreach my $file (split /\n/, $c) {
  if (-f $file.'.voy.gz') {
    print "Y $file\n";
    if (-d $conf->{'--aggregate'}) {
      push @files, $file;
    }
  } else {
    print "N $file\n";
  }
}

if (-d $conf->{'--aggregate'}) {
  foreach my $file (@files) {
    my $command = 'mv '.shell_quote($file.'.voy.gz').' '.shell_quote($conf->{'--aggregate'});
    print $command."\n";
    system $command;
  }
}
