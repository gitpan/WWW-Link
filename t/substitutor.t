#!/usr/bin/perl -w

BEGIN {print "1..6\n"}
END {print "not ok 1\n" unless $loaded;}

use WWW::Link::Repair::Substitutor;

#$::verbose=0xFF;
$::verbose=0;

$loaded = 1;

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

$dirsubs = WWW::Link::Repair::Substitutor::gen_substitutor
  (
   "http://bounce.bounce.com/frodo/dogo" ,
   "http://thing.thong/ding/dong",
   1, #directory substitution
   0,
  );

ref $dirsubs or nogo;
ok(1);

$linksubs = WWW::Link::Repair::Substitutor::gen_substitutor
  (
   "http://bounce.bounce.com/frodo/dogo",
   "http://thing.thong/ding/dong",
   0, #non directory substitution
   0,
  );


ref $dirsubs or nogo;
ok(2);

#tests 3 and 4 :- check that they substitute right

$start = 'this is some text <A HREF="http://bounce.bounce.com/frodo/dogo">';
$target = 'this is some text <A HREF="http://thing.thong/ding/dong">';

$subsme=$start;
&$dirsubs($subsme);
$subsme eq $target or nogo;
ok(3);

$subsme=$start;
&$linksubs($subsme); 
$subsme eq $target or nogo;
ok(4);

#tests 3 and 4 :- check behavior on directory substitutions

$start = 'this is some text <A HREF="http://bounce.bounce.com/frodo/dogo/woggo">';
$target = 'this is some text <A HREF="http://thing.thong/ding/dong/woggo">';


$subsme=$start;
&$dirsubs($subsme);
$subsme eq $target or nogo;
ok(5);

#check linksubs DOESN'T change.
$subsme=$start;
&$linksubs($subsme);
$subsme eq $start or nogo;
ok(6);





