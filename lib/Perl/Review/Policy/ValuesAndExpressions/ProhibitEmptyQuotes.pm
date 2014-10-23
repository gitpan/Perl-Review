package Perl::Review::Policy::ValuesAndExpressions::ProhibitEmptyQuotes;

use strict;
use warnings;
use Perl::Review::Utils;
use Perl::Review::Violation;
use base 'Perl::Review::Policy';

use vars qw($VERSION);
$VERSION = '0.02';

sub violations {
    my ($self, $doc) = @_;
    my $expl = [53];
    my $desc = q{Quotes used with an empty string};
    my $doubles_ref = $doc->find('PPI::Token::Quote::Double') || [];
    my $singles_ref = $doc->find('PPI::Token::Quote::Single') || [];
    my @matches   = grep { m{\A ["|'] \s* ['|"] \z}x } @{$doubles_ref}, @{$singles_ref};
     return map { Perl::Review::Violation->new( $desc, $expl, $_->location() ) } 
      @matches;
}

1;

__END__

=head1 NAME

Perl::Review::Policy::ValuesAndExpressions::ProhibitEmptyQuotes

=head1 DESCRIPTION

Don't use quotes for an empty string or any string that is pure whitespace.
Instead, use C<q{}> to improve legibility.  Better still, created named values
like this.  Use the C<x> operator to repeat characters.

  $message = '';      #not ok
  $message = "";      #not ok
  $message = "     "; #not ok

  $message = q{};     #better
  $message = q{     } #better

  $EMPTY = q{};
  $message = $EMPTY;      #best

  $SPACE = q{ };
  $message = $SPACE x 5;  #best

=head1 SEE ALSO 

L<Perl::Review::Policy::ValuesAndExpressions::ProhibitNoisyStrings>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
