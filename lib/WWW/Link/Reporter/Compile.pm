=head1 NAME

WWW::Link::Reporter::Compile - report link errors suitably for use in emacs

=head1 SYNOPSIS 

    use WWW::Link;
    use WWW::Link::Reporter::Compile;

    $link=new WWW::Link;
    #over time do things to the link ......

    $::reporter=new WWW::Link::Reporter::Compile;
    $::reporter->examine($link)

or see WWW::Link::Selector for a way to recurse through all of the links.

=head1 DESCRIPTION

This is designed for reporting errors in a specific file.  It prints
out an report which is suitable for use by emacs' compile mode.

=cut

package WWW::Link::Reporter::Compile;
use WWW::Link::Reporter;
use English;
@ISA = qw(WWW::Link::Reporter);

sub broken {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  print "$ARGV:$INPUT_LINE_NUMBER: broken link $url\n";
}

=head2 okay

I don't see any reason to call the okay function.. however for
information?  We avoid giving a line number so that this doesn't stop
emacs compile.

=cut

sub okay {
  my $self=shift;
  my $link=shift;
  my $redir=shift;
  my $url=$link->url();
  $redir && print "$ARGV:$INPUT_LINE_NUMBER: ";
  print "tested okay	$url\n";
  $redir && $self->redirections($link);
  $self->suggestions($link);
  return 1;
}

sub damaged {
  my $self=shift;
  my $link=shift;
  my $redir=shift;
  my $url=$link->url();
  print "$ARGV:$INPUT_LINE_NUMBER: _may_ be broken link $url\n";
  $redir && $self->redirections($link);
  $self->suggestions($link);
  return 1;
}

sub not_checked {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  print "$ARGV:$INPUT_LINE_NUMBER: have not yet checked $url\n";
  $self->suggestions($link);
  return 1;
}

sub disallowed {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  print "$ARGV:$INPUT_LINE_NUMBER: checking of link not allowed $url\n";
  $self->suggestions($link);
  return 1;
}

sub unsupported {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  print "$ARGV:$INPUT_LINE_NUMBER: link uses unsupported protocol $url\n";
  $self->suggestions($link);
  return 1;
}

sub unknown {
  my $self=shift;
  my $link=shift;
  my $url=$link->url();
  print "$ARGV:$INPUT_LINE_NUMBER: unknown link status; error?? $url\n";
  $self->suggestions($link);
  return 1;
}

sub not_found {
  my $self=shift;
  my $url=shift;
  print "$ARGV:$INPUT_LINE_NUMBER: no info for $url\n";
}

sub redirections {
  my $self=shift;
  my $link=shift;
  my @redirects=$link->redirect_urls();
  foreach my $redir ( @redirects ) {
    print "    redirected to    $redir\n";
  }
}

sub suggestions {
  my $self=shift;
  my $link=shift;
  my $suggestions=$link->fix_suggestions();
  if ($suggestions) {
    foreach $suggest ( @{$suggestions} ) {
      print "     suggest    $suggest\n";
    }
  }
  return 1;
}
