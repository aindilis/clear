#!/usr/bin/perl -w

use Tk;
use Tk::FileSelect;

my $top = MainWindow->new(-title => "hello");

$FSref = $top->FileSelect(-directory => "/home/andrewdo");

$file = $FSref->Show;
if ($file ne "" and -f $file) {
  print "$file\n";
}
