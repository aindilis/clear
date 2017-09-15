#!/usr/bin/perl -w

# in the future take into account things like content, but for now, just put shorted docs first

use BOSS::Config;
use PerlLib::SwissArmyKnife;

use Error qw(:try);
use File::Stat;
use PDF;

$specification = q(
	-r <readlist>		Reading list to process
);

my $config =
  BOSS::Config->new
  (Spec => $specification);
my $conf = $config->CLIConfig;
# $UNIVERSAL::systemdir = "/var/lib/myfrdcsa/codebases/minor/system";

die "Must specify a valid file with -r flag.\n"  unless -e $conf->{'-r'};

my $pages = {};

my $c = read_file($conf->{'-r'});
foreach my $file (split /\n/, $c) {
  my $command = "file ".shell_quote($file);
  try {
    my $pdf = PDF->new($file);
    my $stat = File::Stat->new($file);
    if ( $pdf->IsaPDF ) {
      $pages->{$file} = $pdf->Pages || $stat->size;
    }
  }
    catch Error::Simple with {
      my $e = $_;
    };
}

foreach my $file (sort {$pages->{$a} <=> $pages->{$b}} keys %$pages) {
  print "$pages->{$file}\t$file\n";
}
