=head1 NAME

WWW::Link::Reporter::LongList - Long list files which contain broken links

=head1 SYNOPSIS

   use WWW::Link;
   use WWW::Link::Reporter::LongList;

   $link=new WWW::Link;

   #over time do things to the link ......

   $reporter = new WWW::Link::Reporter::LongList \*STDOUT, $index;
   $reporter->examine($link)

or see WWW::Link::Selector for a way to recurse through all of the links.

=head1 DESCRIPTION

This is a WWW::Link::Reporter very similar to WWW::Link::Reporter::Text, but
when it detects a broken link in a local file it will list that file
in C<ls -l> format.  This can be used to allow easy editing, for
example by C<link-report-dired> in C<emacs>

=cut

package WWW::Link::Reporter::LongList;

use WWW::Link::Reporter::Text;
@ISA = qw(WWW::Link::Reporter::Text);
use warnings;
use strict;

sub new {
  my $proto=shift;
  my $filebase=pop @_; #reverse order so users put it in the right order.
  my $urlbase=pop @_;
  my $class = ref($proto) || $proto;
  my $self  = $class->SUPER::new(@_);
  $self->{"urlbase"}=$urlbase;
  $self->{"filebase"}=$filebase;
  return $self;
}

sub page_list {
  my $self=shift;
  my @worklist=();
  my @unresolve=();
  my $urlbase=$self->{"urlbase"};
  my $filebase=$self->{"filebase"};
  foreach (@_) {
    #FIXME generalise to use a mapping mechanism
    if (s/$urlbase/$filebase/) {
      push @worklist, $_;
    } else {
      push @unresolve,  $_;
    }
  }
  my $workfile=join ' ', @worklist
    if @worklist;
  print `ls -l $workfile`; 
  print 'unresolved:-  ', join ("\nunresolved:-  ", @unresolve), "\n"
    if @unresolve;
}

