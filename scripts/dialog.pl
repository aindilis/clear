#!/usr/bin/perl -w

# this should be adapted and used again for the time being

my $FILE;
open(FILE,"/usr/bin/sphinx2-demo |") or
  die "can't open sphinx2-demo\n";
my $state = 0;
my $pass;


print "[initializing]\n";
while ($line = <FILE>) {
  chomp $line;
  if ($line =~ /\[initializing\]/) {
    $state = 1;
    print "[initialized]\n";
  } elsif ($state == 1) {
    $pass = 0;
    if ($line =~ /one|what/i) {
      print "Starting reading services\n";
      system "/home/ajd/bin/services -y reading &";
    } elsif ($line =~ /do|two|to/i) {
      print "Starting music services\n";
      system "/home/ajd/bin/services -y music &";
      system "xmms -p &";
    } elsif ($line =~ /three/i) {
      print "Next pdf\n";
      system "ps aux --cols=200 | grep xpdf | awk '{print \$2}' | xargs kill -9";
    } elsif ($line =~ /five/i) {
      print "Stop reading\n";
      system "ps aux --cols=200 | grep -i read-aloud | awk '{print \$2}' | xargs kill -9";
      system "ps aux --cols=200 | grep xpdf | awk '{print \$2}' | xargs kill -9";
    } elsif ($line =~ /four|forward/i) {
      system "xmms -f";
    } elsif ($line =~ /three/i) {
      system "echo aumix -f /home/ajd/myfrdcsa/codebases/meeting/aumix/aumix.mute -L q";
      system "aumix -f /home/ajd/myfrdcsa/codebases/meeting/aumix/aumix.mute -L q";
    } elsif ($line =~ /six/i) {
      system "echo aumix -f /home/ajd/myfrdcsa/codebases/meeting/aumix/aumix.medium -L q";
      system "aumix -f /home/ajd/myfrdcsa/codebases/meeting/aumix/aumix.medium -L q";
    } elsif ($line =~ /backward/i) {
      system "xmms -r";
    } else {
      print "$line\n";
    }
  } else {
    #print "<<<$line>>>\n";
  }
}
