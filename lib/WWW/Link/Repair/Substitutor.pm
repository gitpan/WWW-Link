package WWW::Link::Repair::Substitutor;

=head1 NAME

WWW::Link::Repair::Substitutor - repair links by text substitution

=head1 SYNOPSIS

    use WWW::Link::Repair::Substitutor;
    $dirsubs = WWW::Link::Repair::Substitutor::gen_substitutor
       ( "http://bounce.bounce.com/frodo/dogo" ,
         "http://thing.thong/ding/dong",
          1, 0,  ); #directory substitution don't replace subsidiary links
    &$dirsubs ($line_from_file)

=head1 DESCRIPTION

A module for substituting one link in a file for another.

This link repairer works by going through a file line by line and
doing a substitute on each line.  It will substitute absolute links
all of the time, including within the text of the HTML page.  This is
useful because it means that things like instructions to people about
what to do with URLS will be corrected.

=head1 SUBSTITUTORS

A substituter is a function which substitutes one url for another in a
string.  Typically it would be fed a file a line at a time and would
substitute it directly.  It works on it's argument directly.

The two urls should be provided in absolute form.

=head2 FILE HANDLERS

A file handler goes through files calling a substitutor as needed.

=head2 gen_directory_substitutor

B<Warning>: I think the logic around here is more than a little dubious

=cut

use Carp;
use File::Copy;
use strict;

=head2 gen_substitutor

This function generates a function which can be called either on a
complete line of text from a file or on a URL and which will update
the URL based on the URLs it has been given

If the third argument is true then the function will return a
substitutor which works on all of the links below a given url and
substitutes them all together.  Thus if we change

  http://fred.jim/eating/

to

  http://roger.jemima/food/eating-out/

we also change


  http://fred.jim/eating/hotels.html

to

  http://roger.jemima/food/eating-out/hotels.html

=cut

sub gen_substitutor ($$$$) {
  my ($original_url,$new_url,$tree_mode,$relative) = @_;

  print STDERR "Generating substitutor from ", $original_url,
    " to ", $new_url, "\n" if ($::verbose & 32);


  my $perlcode = <<'EOF';
    sub {
EOF

  $perlcode .= <<'EOF' if ($::verbose & 16);
      print STDERR "Subs in : $_[0]\n";
EOF

  $perlcode .= <<'EOF' if ($relative);
      my $orig_rel=$orig_uri->rel($WWW::Link::Repair::baseurl);
      my $new_rel=$new_uri->rel($WWW::Link::Repair::baseurl);
EOF

  my $restart = <<'EOF';
      $_[0] =~ s,( (?:^) #the start of a line
                  |(?:[^A-Za-z0-9]) #or a boundary character..
	         )
EOF

# $remiddle terminates the url to be replaced...  three possibilities
#
# 1) we are replacing a tree of URLs where the base URL is terminated with a /
#    => what happens after doesn't matter..   '
# 2) we are replacing a tree of URLs where the base URL is unterminated..
#    => end of the string must be end of the URL or '/' must follow
# 3) we only replace the exact URL
#    => end of the string must be end of the URL

  my $remiddle = '';

  unless ($original_url=~ m,/$, and $tree_mode) {
    $remiddle  .= <<'EOF';

                 (?=(
EOF
    my $end_of_uri  = <<'EOF' ;
                     (["'>]) #" this checks for the end of the url..
EOF
    my $end_of_root  = <<'EOF' ;
                     (["'/>]) #" either end or end of section
EOF

    $remiddle  .= ($tree_mode ? $end_of_root : $end_of_uri);

    $remiddle  .= <<'EOF' unless $original_url=~ m,/$,;
		     |(\s)
		     |($)
EOF
    $remiddle  .= <<'EOF';
                    )
                 )
EOF

  }


  $remiddle .= '	        ,$1' ;

  my $reend = ",gxo;\n";
  my $relreend = ",gx;\n";

  #FIXME: url quoting into regex??

  $perlcode .= $restart . $original_url . $remiddle . $new_url . $reend;
  if ($relative) {
    $perlcode .= $restart . '$orig_rel' . $remiddle . '$new_rel' . $relreend;
  }

  $perlcode .= <<'EOF' if ($::verbose & 16);
      print STDERR "Gives : $_[0]\n";
EOF

  $perlcode .= <<'EOF';
    }
EOF
  print STDERR "creating substitutor function as follows\n",$perlcode, "\n"
    if ($::verbose & 32);
  my $returnme=(eval $perlcode);
  if ($@) {
    die "sub creation failed: $@";
  }
  return $returnme;
}


#  sub gen_substitutor ($$$$) {
#    my ($original_url,$new_url,$tree_mode,$relative) = @_;
#    if ($relative) {
#      if ($tree_mode) {
#        return gen_rel_directory_substitutor($original_url, $new_url);
#      } else {
#        return gen_rel_link_substitutor($original_url, $new_url);
#      }
#    } else {
#      if ($tree_mode) {
#        return gen_directory_substitutor($original_url, $new_url);
#      } else {
#        return gen_link_substitutor($original_url, $new_url);
#      }
#    }
#  }

#  sub gen_directory_substitutor ($$) { #original URL, change to URL
#    my ($original_url,$new_url) = @_;
#    croak "gen_directory_substitutor called  with undefined value"
#      unless defined $new_url && defined $original_url;
#    #my $base = shift #???????
#    croak "Orig. and new URL mismatch.  Both or neither should end `/'"
#      unless (  ($original_url =~ m,/$,) == ($new_url =~ m,/$,)   );

#    $original_url=~ m,/$, and
#      return eval '
#        sub {
#  	#print STDERR "substituted at line $.\n" 
#  	#  if 
#  	    $_[0] =~ s,( (?:^)
#  			 |(?:[^A-Za-z0-9])
#  		       )
#  		       $original_url
#  		       ,$1$new_url,gxo;
#        }
#      ';
#    return eval '
#      sub {
#        #print STDERR "substituted at line $.\n" 
#        #  if 
#  	  $_[0] =~ s,( (?:^)
#  		       |(?:[^A-Za-z0-9])
#  		     )
#  		     $original_url
#  		     (?=( (["' . "'" . '/>]) #"
#  			 |(\s)
#  			 |($)
#  			)
#  		     ),$1$new_url,gxo;
#      }
#    ';
#  }

#  sub gen_link_substitutor ($$) { #original URL, change to URL
#    my ($original_url,$new_url) = @_;
#    croak "gen_link_substitutor called  with undefined value"
#      unless defined $new_url && defined $original_url;
#    #my $base = shift #???????
#    return eval {
#      sub {
#        #print STDERR "substituted at line $.\n"
#        #  if 
#  	  $_[0] =~ s,( (?:^)
#  		       |(?:[^A-Za-z0-9])
#  		     )
#  	             $original_url
#  		     (?=( (["'>]) #"
#  	                 |(\s)
#  	                 |($)
#  	                )
#                       ),$1$new_url,gx;
#      }
#    }
#  }

#  =head2 relative substitution

#  When we do substitution of relative URLs we have to also know what is
#  the base url of the current file.  We generate a substitutor like
#  normal, but this one should be passed in the local variable
#  $WWW::Link::Repair::baseurl which will then be used to generate a relative
#  URL for substitution.

#  This substitutor should convert relative URLs to absolute where needed
#  (the original URL can be relative but the new cannot).  It should not
#  convert absolute URLs into relative ones.

#  =cut

#          #first do the substitution on absolute URLs.  This should
#          #mean that there should not be conversion of absolute URLs
#          #into relative URLs.

#          #FIXME: write some regression tests for this.

#  use URI;

#  sub gen_rel_directory_substitutor ($$) { #original URL, change to URL
#    my ($original_url,$new_url) = @_;
#    my $orig_uri=new URI ( $original_url);
#    my $new_uri=new URI ( $new_url);
#    croak "gen_directory_substitutor called  with undefined value"
#      unless defined $new_url && defined $original_url;
#    #my $base = shift #???????
#    croak "Orig. and new URL mismatch.  Both or neither should end `/'"
#      unless (  ($original_url =~ m,/$,) == ($new_url =~ m,/$,)   );

#    $original_url=~ m,/$, and
#      return eval '
#        sub {
#          #calculate the relative URLs..
#          my $orig_rel=$orig_uri->rel($WWW::Link::Repair::baseurl);
#          my $new_rel=$new_uri->rel($WWW::Link::Repair::baseurl);

#  	    $_[0] =~ s,( (?:^)
#  			 |(?:[^A-Za-z0-9])
#  		       )
#  		       $original_url
#  		       ,$1$new_url,gxo;

#  	    $_[0] =~ s,( (?:^)
#  			 |(?:[^A-Za-z0-9])
#  		       )
#  		       $orig_rel
#  		       ,$1$new_rel,gxo;

#        }
#      ';
#    return eval '
#      sub {
#          #calculate the relative URLs..
#          my $orig_rel=$orig_uri->rel($WWW::Link::Repair::baseurl);
#          my $new_rel=$new_uri->rel($WWW::Link::Repair::baseurl);

#  	  $_[0] =~ s,( (?:^)
#  		       |(?:[^A-Za-z0-9])
#  		     )
#  		     $original_url
#  		     (?=( (["' . "'" . '/>]) #"
#  			 |(\s)
#  			 |($)
#  			)
#  		     ),$1$new_url,gxo;
#  	  $_[0] =~ s,( (?:^)
#  		       |(?:[^A-Za-z0-9])
#  		     )
#  		     $orig_rel
#  		     (?=( (["' . "'" . '/>]) #"
#  			 |(\s)
#  			 |($)
#  			)
#  		     ),$1$new_rel,gxo;
#      }
#    ';
#  }

#  sub gen_rel_link_substitutor ($$) { #original URL, change to URL
#    my ($original_url,$new_url) = @_;
#    croak "gen_link_substitutor called  with undefined value"
#      unless defined $new_url && defined $original_url;
#    #my $base = shift #???????
#    return eval {
#      sub {
#        #print STDERR "substituted at line $.\n"
#        #  if 
#  	  $_[0] =~ s,( (?:^)
#  		       |(?:[^A-Za-z0-9])
#  		     )
#  	             $original_url
#  		     (?=( (["'>]) #"
#  	                 |(\s)
#  	                 |($)
#  	                )
#                       ),$1$new_url,gx;
#      }
#    }
#  }

=head2 gen_file_handler(substitutor, basehash)

This function returns a function which will act on a text file or
other file which can be treated as a text file and will carry out
substitutions within it.

B<substitutor> a substitutor function which will be called on each
line of the file and will edit it in place to fix URLs in it.

One problem with this system is that relative URLs are sometimes
possible.  In this case, we can fix these by running a substitution
which handles these.  In this case, provide a hash where the keys are
the directory names and the values are the URLs.

=cut

use vars qw($tmpdir $tmpref $tmpname $keeporig);

$keeporig=1;
$tmpdir="/tmp/";
$tmpref="link_repair";
$tmpname="$tmpdir$tmpref" . "repair.$$";

sub gen_simple_file_handler ($;\%) {
  my ($substitutor) = shift;
  my ($basehash) = shift;

  die "substitutor needs to be a function"
    unless ref ($substitutor) =~ m/CODE/;

  if ($basehash) {
    my $regex="";
    while (my $dir=each(%$basehash) ) {
      my $url=$basehash->{$dir};
      my $regex .= $dir
    }
  } else {
    return sub ($) {
      my ($filename)=@_;
      print STDERR "file handler called for $filename\n" if $::verbose && 8;
      die "file handler called with undefined values" unless defined $filename;
      -d $filename && return 0;
      -f $filename or do {warn "can't fix special file $filename"; return 0};
      if ($WWW::Link::Repair::fakeit) {
	print STDERR "pretending to edit $filename\n";
	-W $filename or warn "file $filename can't be edited";
      } else {
	open (FIXFILE, "<$filename")
	  or do { die "can't access $filename"; return 0};
	open (TMPFILE, ">$tmpname") or die "can't use tempfile $tmpname";
	while (<FIXFILE>) {

	  &$substitutor( $_);
	  print TMPFILE $_;

	}
	close TMPFILE;
	close FIXFILE;
	#FIXME edit failure??    LOGME
	print STDERR "Changed links in file $filename\n"
	  if $WWW::Link::Repair::verbose & 16;
	#FIXME could we do a pure rename(2) solution..
	#   die "filename tainted when should be clean"
	#      if &::is_tainted($filename);
	#I think this is the key bit of the program which needs to be SUID
	#and could even be separated out for more security.. <<EOSU
	rename($filename, $filename . ".orig") if $keeporig;
	copy($tmpname, $filename);
	#EOSU
	unlink $tmpname;	#assuming we used it..
      }
    }
  }
}

# =head3  realativeise

# relativeise makes a relative URL from an absolute one.  This is a
# nasty job to do properly and I can't be bothered yet.

# =cut

=head1 BUGS

One problem with directory substitutors is treatment of the two different urls

  http://fred.jim/eating/

and

  http://fred.jim/eating

Most of the time, the latter of the pair is really just a mistaken
reference to the earlier.  This is B<not> always true.  What is more,
where it is true, a user of LinkController will usually have changed
to the correct version.  For this reason, if gen_directory_substitutor
is passed the first form of a url, it will not substitute the second.
If passed the second, it will substitute the first.

=cut


1;



