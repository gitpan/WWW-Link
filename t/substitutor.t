#!/usr/bin/perl -w

BEGIN {print "1..8\n"}
END {print "not ok 1\n" unless $loaded;}

use WWW::Link::Repair::Substitutor;

#$::verbose=0xFF;
$::verbose=0 unless defined $::verbose;
$WWW::Link::Repair::Substitutor::verbose=0xFFF if $::verbose;

$loaded = 1;

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

#create substitutiors

$linksubs = WWW::Link::Repair::Substitutor::gen_substitutor
  (
   "http://bounce.bounce.com/frodo/dogo",
   "http://thing.thong/ding/dong",
  );


ref $linksubs or nogo;
ok(1);

$dirsubs = WWW::Link::Repair::Substitutor::gen_substitutor
  (
   "http://bounce.bounce.com/frodo/dogo" ,
   "http://thing.thong/ding/dong",
   1, #directory substitution
  );

ref $dirsubs or nogo;
ok(2);

#check that they substitute right

$start = 'this is some text <A HREF="http://bounce.bounce.com/frodo/dogo">';
$target = 'this is some text <A HREF="http://thing.thong/ding/dong">';

$subsme=$start;
&$linksubs($subsme); 
$subsme eq $target or nogo;
ok(3);

$subsme=$start;
&$dirsubs($subsme);
$subsme eq $target or nogo;
ok(4);

#check behavior on directory substitutions

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


$start = 'this is some text <A HREF="woggo">';
$target = 'this is some text <A HREF="http://thing.thong/ding/dong">';

#now try relative substitution

$relsubs = WWW::Link::Repair::Substitutor::gen_substitutor
  (
   "http://bounce.bounce.com/frodo/woggo",
   "http://thing.thong/ding/dong",
   1,
   "http://bounce.bounce.com/frodo/dogo",
  );

ref $linksubs or nogo;
ok(7);

$subsme=$start;
&$relsubs($subsme);
$subsme eq $target or nogo;
ok(8);

