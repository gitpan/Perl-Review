package Perl::Review::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars;

use strict;
use warnings;
use Perl::Review::Utils;
use Perl::Review::Violation;
use base 'Perl::Review::Policy';

use vars qw($VERSION);
$VERSION = '0.04';

sub violations {
    my ($self, $doc) = @_;
    my $expl = [51];
    my $desc = q{String may require interpolation};
    my $nodes_ref = $doc->find( \&_is_single_quote_or_q ) || return;
    my @matches   = grep { _has_interpolation($_) } @{$nodes_ref};
     return map { Perl::Review::Violation->new( $desc, $expl, $_->location() ) } 
      @matches;
}

sub _is_single_quote_or_q {
    my ($doc, $elem) = @_;
    return $elem->isa('PPI::Token::Quote::Single')
	|| $elem->isa('PPI::Token::Quote::Literal');
}

sub _has_interpolation {
    my $elem = shift || return;
    return $elem =~ m{(?<!\\)[\$\@]}x           #Contains unescaped $ or @
	|| $elem =~ m{\\[tnrfae0xcNLuLUEQ]}x;   #Containts escaped metachars
}


1;

__END__

=head1 NAME

Perl::Review::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars

=head1 DESCRIPTION

This policy warns you if you use single-quotes or C<q//> with a string
that has unescaped metacharacters that may need interpoation. Its hard
to know for sure if a string really should be interpolated without
looking into the symbol table.  This policy just makes an educated
guess by looking for metachars and sigils which usually indicate that
the string should be interpolated.

=head1 NOTES

Perl's own C<warnings> pragma also warns you about this.

=head1 SEE ALSO 

L<Perl::Review::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
