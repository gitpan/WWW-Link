#!/usr/bin/perl -w

BEGIN {print "1..4\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

use WWW::Link::Repair;
use WWW::Link::Repair::Substitutor;

#$::verbose=0xFF;
#$::verbose=32;
$::verbose=0;

$loaded = 1;

$text = <<EOF;
<HTML>
<HEAD>
<TITLE>Test file.. for testing repairs</TITLE>
</HEAD>
<BODY>
<P><A HREF="http://bounce.com/">this</A> is a paragraph
with some garbage text <A HREF=http://bounce.com/>about nothing</A>
</P>
</BODY>
</HTML>
EOF


$targettext = $text;

$targettext =~ s/bounce.com/bing.bong/g;


$tfile="/tmp/test.$$";
open(TESTFILE, ">$tfile");
print TESTFILE $text;
close TESTFILE;

$linksubs1 = WWW::Link::Repair::Substitutor::gen_substitutor(
   "http://bounce.com/" ,
   "http://bing.bong/",
   0, 0,
  );

$filehand1 = WWW::Link::Repair::Substitutor::gen_simple_file_handler ($linksubs1);

&$filehand1("$tfile");
open(TESTFILE, "$tfile");

$returntext="";
while ( <TESTFILE> ) {
  $returntext = $returntext . $_;
}

$returntext eq $targettext or nogo;
ok(1);

package myindex;
use vars qw($next %store);

sub new {return bless {}, "myindex"}

%store = (
  'http://www.rum.com/' => 'http://www.fake.com/banana.html',
  'http://www.boredom.com/' => 'http://www.fake.com/strawberry.html',
  'http://www.tardis.ed.ac.uk/~mikedlr/' => 
	    'http://www.fake.com/strawberry.html',
  'http://www.tardis.ed.ac.uk/~mikedlr/climbing/' =>
	    'http://www.fake.com/banana.html'
);

%erost=();

while (my ($key,$value) = each (%store)) {
  $erost{$value}=$key;
}

sub lookup_second {
  my $self=shift;
  $_=shift;
  return [split /\s/, $store{$_}];
}

sub second_set_iterate {
  $next=undef;
  $_[1] eq "http://www.tardis.ed.ac.uk/~mikedlr/"
    and $next="http://www.tardis.ed.ac.uk/~mikedlr/climbing/";
}

sub second_next {my $this=$next; $next=undef; return $this};

package main;

my $index=new myindex;

$oldurl="http://www.rum.com/";
$newurl="http://www.malibu.com/";
$linksubs2=WWW::Link::Repair::Substitutor::gen_substitutor
  (
   $oldurl,
   $newurl,
   0, 0,
  );

$filehand2 = WWW::Link::Repair::Substitutor::gen_simple_file_handler ($linksubs2);

#we want to test infostructure functionality

system 'rm', '-rf', 'work-infostruc';

system 'cp', '-rp', 'sample-infostruc', 'work-infostruc';


#FIXME.. we should probably reject non-absolute paths.. but what the heck
$WWW::Link::Repair::filebase = "./work-infostruc/";
$WWW::Link::Repair::infostrucbase = "http://www.fake.com/";


WWW::Link::Repair::infostructure($index, $filehand2, $oldurl);


$firstdiff = `diff -r  sample-infostruc work-infostruc`;

$firstdiff =~ m($oldurl.*
	      $newurl
	     )xs or nogo;
ok(2);

$linksubs3=WWW::Link::Repair::Substitutor::gen_substitutor
  (
   $oldurl,
   $newurl,
   1, 0,
  );

$filehand3 = WWW::Link::Repair::Substitutor::gen_simple_file_handler ($linksubs3);

#now check that a directory substitution does the same as a normal one
#in the case where there are other links

system 'rm', '-rf', 'work-infostruc';

system 'cp', '-rp', 'sample-infostruc', 'work-infostruc';

WWW::Link::Repair::infostructure($index, $filehand3, $oldurl, 1);

$seconddiff = `diff -r  sample-infostruc work-infostruc`;

$seconddiff eq $firstdiff or nogo;

ok(3);

$oldurl="http://www.tardis.ed.ac.uk/~mikedlr/";
$newurl="http://www.mikedlr.org/~mikedlr/";

$linksubs4=WWW::Link::Repair::Substitutor::gen_substitutor
  (
   $oldurl,
   $newurl,
   1, 0,
  );


$filehand4 = WWW::Link::Repair::Substitutor::gen_simple_file_handler ($linksubs4);


#now check directory substitution proper

system 'rm', '-rf', 'work-infostruc';

system 'cp', '-rp', 'sample-infostruc', 'work-infostruc';

WWW::Link::Repair::infostructure($index, $filehand4, $oldurl, 1);

$thirddiff = `diff -r  sample-infostruc work-infostruc`;

$thirddiff =~ m(($oldurl [^c].*
		 $newurl [^c].*
		 $oldurl climbing/ .*
		 $newurl climbing/ .*
		) | 
		($oldurl climbing/ .*
		 $newurl climbing/ .*
		 $oldurl [^c].*
		 $newurl [^c].*
		)
	     )xs or nogo;
ok(4);


system 'rm', '-rf', 'work-infostruc';


