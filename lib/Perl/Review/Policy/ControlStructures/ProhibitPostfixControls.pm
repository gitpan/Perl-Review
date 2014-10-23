package Perl::Review::Policy::ControlStructures::ProhibitPostfixControls;

use strict;
use warnings;
use Pod::Usage;
use List::MoreUtils qw(any);
use Perl::Review::Violation;
use Perl::Review::Utils;
use base 'Perl::Review::Policy';

use vars qw($VERSION);
$VERSION = '0.02';

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;

    #Be flexible with configuration
    if (ref $args{allow} eq 'ARRAY'){
	#Allowed controls can be in array ref
	$self->{_allow} = delete $args{allow};
    }
    elsif ($args{allow}) {
	#Allowed controls can be in space-delimited string
	$self->{_allow} = [split m{\s+}, delete $args{allow}];
    }
    else {
	#Deafult to allow nothing
	$self->{_allow} = [];
    }

    #Sanity check for bad configuration.  We deleted all the args
    #that we know about, so there shouldn't be anything left.
    if(%args) {
	my $msg = "Unsupported arguments to __PACKAGE__->new(): ";
	$msg .= join $COMMA, keys %args;
	pod2usage(-message => $msg, -input => __FILE__ , -verbose => 2);
    }

    return $self;
}


sub violations {
    my ($self, $doc) = @_;

    #Define controls and their page numbers in PBB
    my %pages_of = (if     => [93,94],  for    => [96],
		    while  => [96],     unless => [96,97],
		    until  => [96,97]);

    my @matches = ();

  CONTROL:
    for my $control ( keys %pages_of ){
	next CONTROL if any {$control eq $_} @{$self->{_allow}};
	my $nodes_ref = find_keywords( $doc, $control ) || next;

      NODE:
	for my $node ( @{$nodes_ref} ) {

	    #Control word 'if' is allowed only if it is part of a loop break
	    next NODE if ($control eq 'if' and $node->statement->isa('PPI::Statement::Break') );
		
	    #If the control word is preceeded by something, then it must be postfix
	    if( $node->sprevious_sibling() ){
		my $desc = qq{Postfix control '$control' used};
		my $expl = $pages_of{$control};
		push @matches, Perl::Review::Violation->new( $desc, $expl, $node->location() );
	    }
	}
    }
    return @matches;
}

1;

__END__

=head1 NAME

Perl::Review::Policy::ControlStructures::ProhibitPostfixControls

=head1 DESCRIPTION

Conway discourages using postfix control structures (C<if>, C<for>,
C<unless>, C<until>, C<while>).  The C<unless> and C<until> controls
are particularly evil becuase the lead to double-negatives that are
hard to comprehend.  The only tolerable usage of a postfix C<if> is
when it follows a loop break such as C<last>, C<next>, C<redo>, or
C<continue>.

  do_something() if $condition;         #not ok
  if($condition){ do_something() }      #ok

  do_something() while $condition;      #not ok
  while($condition){ do_something() }   #ok

  do_something() unless $condition;     #not ok
  do_something() unless ! $condition;   #really bad
  if(! $condition){ do_something() }    #ok

  do_something() until $condition;      #not ok
  do_something() until ! $condition;    #really bad
  while(! $condition){ do_something() } #ok 

  do_something($_) for @list;           #not ok

 LOOP:
  for my $n (0..100){
      next if $condition;               #ok
      last LOOP if $other_condition;    #also ok
  }

=head1 CONSTRUCTOR

This policy accepts an additional key-value pair in the C<new> method.
The key should be 'allow' and the value should be a reference to an
array of postfix control keywords that you want to allow.
Alternatively, the value can be a string of space-delimited keywords.
Choose from C<if>, C<for>, C<unless>, C<until>,and C<while>.  When
using the L<Perl::Review> engine, these can be configured in the
F<.perlreviewrc> file like this:

 [ControlStructures::ProhibitPostfixControls]
 allow = for if

 #or 

 [ControlStructures::ProhibitPostfixControls]
 allow = for
 allow = if

By default, all postfix control keywords are prohibited.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
