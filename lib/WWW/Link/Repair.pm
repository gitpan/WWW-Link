package WWW::Link::Repair;

=head1 NAME

Repair.pm - repair links in files.

=head1 SYNOPSIS

    use Repair::Substitutor;
    use Repair;

    $linksubs1 = WWW::Link::Repair::Substitutor::gen_substitutor(
       "http://bounce.com/" ,
       "http://bing.bong/",
       0, 0,
      );
    $filehand = WWW::Link::Repair::Substitutor::gen_simple_file_handler ($linksubs);

    &$filehand("fix-this-file");

    use CDB_File::BiIndex;
    $::index = new CDB_File::BiIndex "page-index-file", "link-index-file";

    WWW::Link::Repair::infostructure($index, $filehand, "http://bounce.com/");


=head1 DESCRIPTION

This module provides functions that allow the repair of files.

=cut

$WWW::Link::Repair::fakeit = 0;
$WWW::Link::Repair::verbose = 0;

use File::Copy;
use Carp;
use strict;

=head2 directory(file handler, directory ... )

This function recurses through each given directory argument.  For
each file found it calls the file handler function.

The B<file handler> should be a function which can be called on a
filename and will update that file with the new URL.

B<oldurl> is the base URL which should be iterated from.  It must
exist within the B<index>.

B<as_directory> controlls whether to attempt to replace all links
below that link.  In this case the index is iterated beyond the first
link for all links which begin with the first link.

=cut

sub directory {
  my $handler=shift;
  my $sub = sub {-d && return 0; &$handler($File::Find::name)};
  File::Find::find($sub, @_);
}

=head2 infostructure(index object, file handler, oldurl, as_directory)

This function will use a previously build index to update all of the
files referenced from that index that need updating.

The B<index> object will be treated as a BiIndex.

The B<file handler> should be a function which can be called on a
filename and will update that file with the new URL.

B<oldurl> is the base URL which should be iterated from.  It must
exist within the B<index>.

B<as_directory> controlls whether to attempt to replace all links
below that link.  In this case the index is iterated beyond the first
link for all links which begin with the first link.

=cut

use vars qw($infostrucbase $filebase);

sub infostructure ($$$;$) {
  my ($index, $file_handler, $oldurl, $as_directory)=@_;
  my $editlist=$index->lookup_second($oldurl);
  unless ($editlist) {
    warn "There were no files with that link to edit.\n";

    #FIXME.. 

    #we need some way of entering the index just before a given
    #key.. this means either starting at the beginning or putting
    #convenient jump in points, such as host names, in the
    #index.. e.g. if we have http://joe.bloggs/this/that.html then we
    #guarantee that http://joe.bloggs/ will be there with an empty
    #value..  That means changing all other iterators etc.

    warn "..and due to a bug I will have missed your sub-links.. sorry\n"
      if $as_directory;
    return 0;
  }

  my $member;
  foreach $member (@$editlist) {
    print STDERR "going to convert $member to file\n"
	if $WWW::Link::Repair::verbose & 32;
    my $file = map_url_to_editable($member);
    print STDERR "file is $file\n" if $WWW::Link::Repair::verbose & 32;
    &$file_handler($file);
  }

  $index->second_set_iterate($oldurl);

  if ($as_directory) { #we should substitute all links below this
    my $key;
    while ($key = $index->second_next()) {
      last unless $key =~ m/^$oldurl/;
      my $editlist=$index->lookup_second($key);
      my $member;
      foreach $member (@$editlist) {
	print STDERR "going to convert $member to file\n"
	    if $WWW::Link::Repair::verbose & 32;
	my $file = map_url_to_editable($member);
	print STDERR "file is $file\n" if $WWW::Link::Repair::verbose & 32;
	&$file_handler($file);
      }
    }
  } else { #just warn if there are any links below this.
    my $next=$index->second_next();
    warn "Ignoring some other URLs which start with your URL.\n"
      if $next && $next =~ m/^$oldurl/;
  }
  #FIXME repair the infostructure index..
}

=head2 map_url_to_editable

Given any url, get us something we can edit in order to change the
resource referenced by that url.  Or not, if we can't.  In the case
that we can't, return undef.

The aim of this function is to return something which is not tainted.

N.B.  This will accept any filename which is within the infostructure
whatsoever.. it is possible that that includes more than you wish to
let people edit.

For this function to work the two variables:

  $WWW::Link::Repair::filebase
  $WWW::Link::Repair::infostrucbase

must be defined appropriately

=cut

# sub{}

# @conversions = [
#   { regexp => 'http:://stuff..../'
#     changeurlfunc => sub {

#     }

# ]

sub map_url_to_editable ($) {
  my $save=$_;
  $_=shift;
  print STDERR "trying to map $_ to editable object\n"
    if $WWW::Link::Repair::verbose & 64;

  unless (m/^$infostrucbase/) {
    my $print=$_;
    $_=$save;
    croak "can't deal with url '$print' not in our infostructure"; #taint??
  }
  die 'config variable $WWW::Link::Repair::infostrucbase must be defined' 
    unless defined $infostrucbase;
  s/^$infostrucbase//;

  # Now we clean up the filename.  For This we assume unix semantics.
  # These have been around for long enough that any sensible operating
  # system could have simply copied them.

  s,/./,,g;

  #now chop away down references..

  # substitute a downchange (dirname/) followed by an upchange ( /../ )
  # for nothing.
  1 while s,([^.]|(.[^.])|(..?))/+..($|/),,g ;

  # clean up multiple slashes

  s,//,/,g;

  # delete leading slash

  s,^/,,g;


  if (m,(^|/)..($|/),) {
    $_=$save;
    croak "upreferences (/../) put that outside our infostructure";
  }

  #what are the properties of the filename we can return..
  #any string which doesn't contain /.. (and refuse /.

  #now we untaint and do a check..

  $_ =~ m,( (?:             # directory name; xxx/ or filename; xxx
	         (?:                # some filename ....
	           (?:[^./][^/]+)              #a filename with no dot
	          |(?:.[^./][^/]+)             #a filename starting with .
	          |(?:..[^./][^/]+)            #a filename starting with .. why bother?
	         )
	         (?:/|$)           # seperator to next directory name or end of filename
	      ) +
	    ),x; #we set $1 to the whole qualified filename.

  my $fixable = $1;
  $_=$save;
  return undef unless defined $fixable;
  die 'config variable $WWW::Link::Repair::filebase must be defined'
    unless defined $filebase;
  #FIXME: filebase can contain a / so this can end up with //. do we care?
  return $filebase . '/' . $fixable; #filebase should be an internal variable
}


=head1 check_url_is_full

The aim of this function is to check whether a given url is full

=cut


sub check_url ($) {
  my $fixable=shift;
 FIXABLE: foreach (@$fixable) {
    m,^[A-Za-z]+://^[A-Za-z]+/, or die "unqualified URL in database $_";
  }
}

1; #why are we all afraid of require?  Why do we give in??
