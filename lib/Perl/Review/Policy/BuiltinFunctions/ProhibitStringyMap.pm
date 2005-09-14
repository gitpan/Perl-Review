package Perl::Review::Policy::BuiltinFunctions::ProhibitStringyMap;

use strict;
use warnings;
use Perl::Review::Utils;
use Perl::Review::Violation;
use base 'Perl::Review::Policy';

use vars qw($VERSION);
$VERSION = '0.04';

sub violations {
    my ($self, $doc) = @_;
    my $expl = [169];
    my $desc = q{String form of 'map'};
    my $nodes_ref = find_keywords( $doc, 'map' ) || return;
    my @matches = grep { ! _first_arg_is_block($_) } @{$nodes_ref};
    return map { Perl::Review::Violation->new( $desc, $expl, $_->location() ) } 
      @matches;
}

sub _first_arg_is_block {
    my $elem = shift || return;
    my $sib = $elem->snext_sibling() || return;
    my $arg = $sib->isa('PPI::Structure::List') ? $sib->schild(0) : $sib;
    return $arg && $arg->isa('PPI::Structure::Block');
}

1;

__END__

=head1 NAME

Perl::Review::Policy::BuiltinFunctions::ProhibitStringyMap

=head1 DESCRIPTION

The string form of C<grep> and C<map> is awkward and hard to read.
Use the block forms instead.

  @matches = grep "/pattern/", @list;        #not ok
  @matches = grep {/pattern/}  @list;        #ok

  @mapped = map "transform($_)", @list;      #not ok
  @mapped = map {transform($_)}  @list;      #ok


=head1 SEE ALSO

L<Perl::Review::Policy::ControlStrucutres::ProhibitStringyEval>

L<Perl::Review::Policy::ControlStrucutres::ProhibitStringyGrep>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
