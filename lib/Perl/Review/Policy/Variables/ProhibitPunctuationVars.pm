package Perl::Review::Policy::Variables::ProhibitPunctuationVars;

use strict;
use warnings;
use Perl::Review::Utils;
use Perl::Review::Violation;
use base 'Perl::Review::Policy';

use vars qw($VERSION);
$VERSION = '0.04';

sub violations {
    my ($self, $doc) = @_;
    my $expl = [79];
    my $desc = q{Magic punctuation variable used};
    my $nodes_ref = $doc->find('PPI::Token::Magic') || return;
    #Filter out $_ and @_.  These are common enough to allow.
    my @matches = grep { $_ !~ m{\A [\$\@]_ \z}x } @{$nodes_ref};
    return map { Perl::Review::Violation->new( $desc, $expl, $_->location() ) } 
      @matches;
}

1;

__END__

=head1 NAME

Perl::Review::Policy::Variables::ProhibitPunctuationVars

=head1 DESCRIPTION

Perl's vocabulary of punctuation variables such as C<$!>, C<$.>, and
C<$^> are perhaps the leading cause of its repuation as inscrutable
line noise.  The simple alternative is to use the L<English> module to
give them clear names.

  $| = undef;                      #not ok

  use English qw(-no_match_vars);
  local $OUTPUT_AUTOFLUSH = undef;        #ok

=head1 NOTES

The scratch variables C<$_> and C<@_> are very common and have no
equivalent name in L<English>, so they are exempt from this policy.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
