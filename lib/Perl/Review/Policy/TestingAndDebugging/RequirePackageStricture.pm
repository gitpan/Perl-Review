package Perl::Review::Policy::TestingAndDebugging::RequirePackageStricture;

use strict;
use warnings;
use Perl::Review::Utils;
use List::Util qw(first);
use base 'Perl::Review::Policy';

use vars qw($VERSION);
$VERSION = '0.03';

sub violations{
    my ($self, $doc) = @_;
    my $expl = [429];
    my $desc = q{Code before strictures are enabled};

    #Find first statement that isn't 'use', 'require', or 'package'
    my $nodes_ref  = $doc->find('PPI::Statement') || return;
    my $other_stmnt = first {   !$_->isa('PPI::Statement::Package')
			     && !$_->isa('PPI::Statement::Include')} @{$nodes_ref};

    #Find the first 'use strict' statement
    my $strict_stmnt = first {   $_->isa('PPI::Statement::Include')
			      && $_->type() eq 'use'
			      && $_->pragma() eq 'strict'} @{$nodes_ref};

    $other_stmnt || return;           #Both of these...
    $strict_stmnt ||= $other_stmnt;   #need to be defined
    my $other_at  =  $other_stmnt->location()->[0];
    my $strict_at = $strict_stmnt->location()->[0];
    
    return $other_at <= $strict_at ?
	Perl::Review::Violation->new($desc, $expl, $other_stmnt->location()) : ();
}

1;

__END__

=head1 NAME

Perl::Review::Policy::TestingAndDebugging::RequirePackageStricture

=head1 DESCRIPTION

Using strictures is probably the single most effective way to improve
the quality of your code.  This policy requires that the C<'use
strict'> statement must come before any other staments except
C<package>, C<require>, and other C<use> statements.  Thus, all the
code in the entire package will be affected.

=head1 SEE ALSO

L<Perl::Review::Policy::TestingAndDebugging::RequirePackageWarnings>

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module
