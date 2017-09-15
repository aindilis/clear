#!/usr/bin/perl -w

defined($pid = fork()) or die "Cannot fork()!\n";
if ($pid) {
  print "I am the parent of $pid\n";
  sleep(5);
  print "I am ending the child process\n";
  kill 9, $pid;
  sleep(5);
} else {
  print "I am the child\n";
  exec "xview -shrink /home/andrewdo/andrew-meetup.jpg";
}
