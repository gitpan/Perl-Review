package Perl::Review::Policy::Modules::ProhibitRequireStatements;

use strict;
use warnings;
use Perl::Review::Utils;
use Perl::Review::Violation;
use base 'Perl::Review::Policy';

use vars qw($VERSION);
$VERSION = '0.04';

sub violations {
    my ($self, $doc) = @_;
    my $expl = q{Use 'use' pragma instead};
    my $desc = q{Deprecated 'require' statement used};
    my $nodes_ref = $doc->find('Statement::Include') || return;
    my @matches   = grep { $_->type() eq 'require' } @{$nodes_ref};
    return map { Perl::Review::Violation->new( $desc, $expl, $_->location() ) } 
      @matches;
}

1;

__END__

=head1 NAME

Perl::Review::Policy::Modules::ProhibitRequireStatements

=head1 DESCRIPTION

Since Perl 5, C<require> statements are pretty much obsolete.  Use the
C<use> pragma instead.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
