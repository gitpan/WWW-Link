#!/usr/bin/perl -w

=head1 NAME

tester - test the testers

=head1 SYNOPSYS

tester.t

=head1 DESCRIPTION

In order to test the testers, we write our own fake user agent..

=cut

our $loaded;

BEGIN {print "1..42\n"}
END {print "not ok 1\n" unless $loaded;}

use warnings;
use strict;

sub nogo {print "not "}
sub ok {my $t=shift; print "ok $t\n";}

package LWP::FakeAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Status;
use WWW::Link::Tester; #import response codes to this package
use Carp;

sub new {
  my $class=shift;
  my $self=bless {}, $class;
  return $self;
}

sub is_protocol_supported { 
    my($self, $scheme) = @_;
    if (ref $scheme) {
	# assume we got a reference to an URI object
	$scheme = $scheme->scheme;
    } else {
	Carp::croak("Illegal scheme '$scheme' passed to is_protocol_supported")
	    if $scheme =~ /\W/;
	$scheme = lc $scheme;
    }
    return 1 if $scheme =~ m/^http$/;
    return 0;
}

sub simple_request {
  my $self=shift;
  my $request=shift;
  my $uri=$request->uri();
  my $uri_str=$uri->as_string;
  my $response;
 CASE: foreach ($uri_str) {
    m,^http://www.broken.com, && do {
      $response=new HTTP::Response (RC_NOT_FOUND, "Simulated broken page");
      last;
    };
    m,^http://www.okay.com, && do {
      $response=new HTTP::Response (RC_OK, "Simulated working page");
      last;
    };
    m,^http://www.redirected.com, && do {
      $response=new HTTP::Response (RC_TEMPORARY_REDIRECT,
			"Simulated redirect");
      $response->push_header( Location => 'http://www.target.com/hi.there' );
      last;
    };
    m,^http://www.target.com/hi.there, && do {
      $response=new HTTP::Response (RC_OK, "Simulated working page");
      last;
    };
    m,^http://www.indefinite.com, && do {
      $response=new HTTP::Response (RC_TEMPORARY_REDIRECT,
				    "Simulated redirect");
      m,^http://www.indefinite.com.*[^/]$, and $uri_str .= '/';
      $response->push_header( Location => $uri_str . 'l/' );
      last;
    };
    m,^http://www.paranoid.com, && do {
      $response=new HTTP::Response (RC_FORBIDDEN,
				    "Simulated robots.txt exclusion");
      last;
    };
    m,^whoop:wozzisprogogogl, && do {
	die "unsupported protocol allowed through to testing";
      $response=new HTTP::Response (RC_PROTOCOL_UNSUPPORTED,
				    "Simulated unsupported protocol");
      last;
    };
    die "unknown request $_";
  }
  return $response;
}

package main;

use WWW::Link;
use WWW::Link::Tester;
use WWW::Link::Tester::Adaptive;
use WWW::Link::Tester::Simple;
use WWW::Link::Tester::Complex;
ok(1);
$loaded=1;
use vars qw($simplet $complext $adaptivet);

our ($working_link,  $broken_link,  $redirected_link, $infinite_link,
    $robot_blocked_link, $unsupported_link, $ua);

$working_link = new WWW::Link "http://www.okay.com";
$broken_link = new WWW::Link "http://www.broken.com";
$redirected_link=new WWW::Link "http://www.redirected.com";
$infinite_link=new WWW::Link "http://www.indefinite.com";
$robot_blocked_link=new WWW::Link "http://www.paranoid.com/deepwithin.html";
$unsupported_link=new WWW::Link "whoop:wozzisprogogoglisnoideawozzoever";

$ua=new LWP::FakeAgent;

$simplet=new WWW::Link::Tester::Simple $ua;

$simplet->test_link($working_link);
ok(2);
nogo unless ($working_link->is_okay());
ok(3);
$simplet->test_link($broken_link);
nogo if ($broken_link->is_okay());
ok(4);
$simplet->test_link($redirected_link);
ok(5);
nogo unless ($redirected_link->is_okay());
ok(6);
nogo unless ($redirected_link->is_redirected());
ok(7);
$simplet->test_link($infinite_link);
nogo if ($infinite_link->is_okay());
ok(8);
$simplet->test_link($unsupported_link);
nogo unless ($unsupported_link->is_unsupported());
ok(9);
nogo if ($unsupported_link->is_okay());
ok(10);
nogo if ($unsupported_link->is_broken());
ok(11);
$simplet->test_link($robot_blocked_link);
nogo unless ($robot_blocked_link->is_disallowed());
ok(12);
nogo if ($robot_blocked_link->is_okay());
ok(13);
nogo if ($robot_blocked_link->is_broken());
ok(14);

$working_link = new WWW::Link "http://www.okay.com";
$broken_link = new WWW::Link "http://www.broken.com";
$redirected_link=new WWW::Link "http://www.redirected.com";
$infinite_link=new WWW::Link "http://www.indefinite.com";
$robot_blocked_link=new WWW::Link "http://www.paranoid.com/deep/within.html";
$unsupported_link=new WWW::Link "whoop:wozzisprogogoglisnoideawozzoever";

$complext=new WWW::Link::Tester::Complex $ua;

$complext->test_link($working_link);
ok(15);
nogo unless ($working_link->is_okay());
ok(16);
$complext->test_link($broken_link);
nogo if ($broken_link->is_okay());
ok(17);
$complext->test_link($redirected_link);
ok(18);
nogo unless ($redirected_link->is_okay());
ok(19);
nogo unless ($redirected_link->is_redirected());
ok(20);
$complext->test_link($infinite_link);
nogo if ($infinite_link->is_okay());
ok(21);
nogo if ($infinite_link->is_okay());
ok(22);
$simplet->test_link($unsupported_link);
nogo unless ($unsupported_link->is_unsupported());
ok(23);
nogo if ($unsupported_link->is_okay());
ok(24);
nogo if ($unsupported_link->is_broken());
ok(25);
$simplet->test_link($robot_blocked_link);
nogo unless ($robot_blocked_link->is_disallowed());
ok(26);
nogo if ($robot_blocked_link->is_okay());
ok(27);
nogo if ($robot_blocked_link->is_broken());
ok(28);

$working_link = new WWW::Link "http://www.okay.com";
$broken_link = new WWW::Link "http://www.broken.com";
$redirected_link=new WWW::Link "http://www.redirected.com";
$infinite_link=new WWW::Link "http://www.indefinite.com";
$robot_blocked_link=new WWW::Link "http://www.paranoid.com/deep/within.html";
$unsupported_link=new WWW::Link "whoop:wozzisprogogoglisnoideawozzoever";

$adaptivet=new WWW::Link::Tester::Adaptive $ua;

$adaptivet->test_link($working_link);
ok(29);
nogo unless ($working_link->is_okay());
ok(30);
$adaptivet->test_link($broken_link);
nogo if ($broken_link->is_okay());
ok(31);
$adaptivet->test_link($redirected_link);
ok(32);
nogo unless ($redirected_link->is_okay());
ok(33);
nogo unless ($redirected_link->is_redirected());
ok(34);
$adaptivet->test_link($infinite_link);
nogo if ($infinite_link->is_okay());
ok(35);
nogo if ($infinite_link->is_okay());
ok(36);
$simplet->test_link($unsupported_link);
nogo unless ($unsupported_link->is_unsupported());
ok(37);
nogo if ($unsupported_link->is_okay());
ok(38);
nogo if ($unsupported_link->is_broken());
ok(39);
$simplet->test_link($robot_blocked_link);
nogo unless ($robot_blocked_link->is_disallowed());
ok(40);
nogo if ($robot_blocked_link->is_okay());
ok(41);
nogo if ($robot_blocked_link->is_broken());
ok(42);

