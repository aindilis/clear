package Clear::Util;

use strict;
use Exporter;
use Carp;
use POSIX;
use Lingua::Stem::AutoLoader;
use vars qw (@ISA @EXPORT_OK @EXPORT $VERSION);

my $prompt = "> ";

BEGIN {
    $VERSION     = '0.1';
    @ISA         = qw (Exporter);
    @EXPORT      = qw (Approve ApproveCommand Message Query YesNoQuery
                       Choose Debug GreaterTime ConvertTimeToAbs ConvertTimeToTime ConvertTimeToHours);
    @EXPORT_OK   = qw (Approve ApproveCommand Message Query YesNoQuery
                       Choose Debug GreaterTime ConvertTimeToAbs ConvertTimeToTime ConvertTimeToHours);
}

sub Approve {
  my ($message) = (shift);
  print "<<<$message>>>\n";
  my $response = <STDIN>;
  if ($response =~ /y/i) {
    return 1;
  }
}

sub ApproveCommand {
  my ($command) = (shift);
  if (Approve("Execute this command? <<<$command>>>")) {
    system $command;
  }
}

sub Message {
  my ($message) = (shift);
  $message =~ s/[\n\s]+$//;
  print "$message\n";
}

sub Query {
  my ($query) = (shift);
  Message($query);
  print $prompt;
  my $ans = <STDIN>;
  chomp $ans;
  print "($ans)\n";
  return $ans;
}

sub YesNoQuery {
  my ($query) = (shift);
  my $ans;
  while (($ans = Query($query)) && ($ans !~ /^([yn]|yes|no)$/i)) { }
  return $ans =~ /y(es)?/i;
}

sub Choose {
  my (@options) = (@_);
  if (scalar @options > 1) {
    my $i = 0;
    foreach my $option (@options) {
      chomp $option;
      print "$i) $option\n";
      $i = $i + 1;
    }
    print $prompt;
    my $ans = <STDIN>;
    chomp $ans;
    print "($ans)\n";
    return $options[$ans];
  } elsif (scalar @options == 1) {
    return $options[0];
  }
}

sub Debug {
  my $message = shift;
  if ($UNIVERSAL::debug) {
    Message($message);
  }
}

sub GreaterTime {
  my ($t1,$t2) = (shift,shift);
  $t1 =~ /^([0-9]{1,2}):([0-9]{2})([ap])$/;
  my @ti1 = ($1,$2,$3);
  $t2 =~ /^([0-9]{1,2}):([0-9]{2})([ap])$/;
  my @ti2 = ($1,$2,$3);
  if ($ti1[2] eq "p") {
    if ($ti2[2] eq "a") {
      return 1;
    }
  } elsif ($ti1[2] eq "a") {
    if ($ti2[2] eq "p") {
      return 0;
    }
  }
  if ($ti1[0] > $ti2[0]) {
    return 1;
  } elsif ($ti1[0] < $ti2[0]) {
    return 0;
  } elsif ($ti1[0] == $ti2[0]) {
    if ($ti1[1] > $ti2[1]) {
      return 1;
    } elsif ($ti1[1] < $ti2[1]) {
      return 0;
    } else {
      return 1;
    }
  }
}

sub ConvertTimeToAbs {
  my ($time) = (shift,shift);
  $time =~ /^([0-9]{1,2}):([0-9]{2})([ap])$/;
  return ($1 % 12) + ($2 / 60) + 12 * ($3 eq "p");
}

sub ConvertTimeToTime {
  my ($time) = (shift,shift);
  my $t1 = int($time);
  my $t2 = ceil(($time - $t1) * 60);
  return sprintf("%i:%02i",$t1,$t2);
}

sub ConvertTimeToHours {
  my ($time) = (shift,shift);
  my $t1 = int($time);
  my $t2 = int(($time - $t1) * 60);
  $t1 = $t1 % 12;
  if (!$t1) {
    $t1 = 12;
  }
  my $t3 = $time > 12 ? "p" : "a";
  return sprintf("%i:%02i%s", $t1,$t2,$t3);
}

1;
