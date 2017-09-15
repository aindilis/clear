#!/usr/bin/perl -w

use KBS2::Client;
use PerlLib::SwissArmyKnife;

my $client = KBS2::Client->new
  (
   Context => 'Org::FRDCSA::Clear::DocData',
  );

my $res1 = $client->Send
  (
   QueryAgent => 1,
   Assert => [['r',['d',1],['s',1],['to',1]]],
   InputType => 'Interlingua',
   Flags => {
	     AssertWithoutCheckingConsistency => 1,
	    },
  );

print Dumper({Res1 => $res1});
