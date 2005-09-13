package Perl::Review;

use strict;
use warnings;
use English qw(-no_match_vars);
use File::Spec::Functions qw(catfile);
use Perl::Review::Config;
use Carp;
use PPI;

use vars qw($VERSION);
$VERSION   = '0.02';

#----------------------------------------------------------------------------
#
sub new {

    my ($class, %opts) = @_;

    # Default arguments
    my $priority = defined $opts{-priority} ? $opts{-priority} : 0;
    my $profile  = $opts{-profile};

    # Create object
    my $self = bless {}, $class;
    $self->{_policies} = [];

    # Allow all configuration to be skipped. This
    # is useful for testing an isolated policy.
    return $self if defined $profile && $profile eq 'NONE';

    # Read configuration
    my $config  = Perl::Review::Config->new(-profile => $profile);

    # Now apply policy configuration
    while( my ($policy, $args) = each %{$config} ){
	next if ! $policy;                     #Skip default section
	$args = {} if ! defined $args;         #Protect against undefined config
	my $p = delete $args->{priority};      #Remove 'priority' from config
	$p = 1 if ! defined $p;                #Default the priority
	next if $priority && ($p > $priority); #Skip 'low' priority policies
	$self->add_policy($policy, %{$args});  #Add policy with remaining config
    }
    return $self;
}

#----------------------------------------------------------------------------
#
sub add_policy {

    my ($self, $module_name, %args) = @_;
    
    return if ! $module_name;

    #Qualify name if full module name not given
    my $namespace = 'Perl::Review::Policy';
    $module_name = $namespace . '::' . $module_name
	if $module_name !~ m{ \A $namespace }x;

    #Convert module name to file path.  I'm trying to do
    #this in a portable way, but I'm not sure it actually is.
    my $module_file = catfile( split '::', $module_name );
    $module_file .= '.pm';

    #Try to load module and instantiate
    eval {
	require $module_file;
	my $policy = $module_name->new(%args);
	push @{$self->{_policies}}, $policy;
    };

    #Failure to load is not fatal
    if($EVAL_ERROR) {
	carp "Can't load policy module $module_name: $EVAL_ERROR";
	return;
    }
    
    return $self;
}

#----------------------------------------------------------------------------
#
sub review_code {
    my ($self, $source_code) = @_;

    #Parse the code
    my $doc = PPI::Document->new($source_code) || croak q{Cannot parse code};
    $doc->index_locations();

    #Apply policies and return violations
    return map { $_->violations($doc) } @{$self->{_policies}}; 
}

1;

__END__

=head1 NAME

Perl::Review - Engine to critique Perl souce code

=head1 SYNOPSIS

  use Perl::Review;

  #Create Review and load Policies from config file
  $r = Perl::Review->new(-profile => $file);

  #Create Review from scratch and add Policy
  $r = Perl::Review->new();
  $r->add_policy('MyPolicyModule');

  #Analyze code for policy violations
  @violations = $r->review_code($source_code);

=head1 DESCRIPTION

Perl::Review is an extensible framework for creating and applying
coding standards to Perl source code.  It is, essentially, an
automated code review.  Perl::Review is distributed with a number
of L<Perl::Review::Policy> modules that enforce the guidelines in
Damian Conway's book B<Perl Best Practices>.  You can choose and
customize those Polices through the Perl::Review interface.  You
can also create new and use new Policy modules that suit your own
tastes.

For a convenient command-line interface to Perl::Review, see the
documentation for L<perlreview>.

=head1 CONSTRUCTOR

=over 8

=item new( -profile => $FILE, -priority => $N )

Returns a reference to a Perl::Review object.  All arguments are
optional key-value pairs.

B<-profile> is the path to a configuration file that dictates which
policies should be loaded and how to configure each one. If the
C<$FILE> is not defined, Perl::Review attempts to find a
configuration file in several places.  If a configuration file can't
be found, or if C<$FILE> is empty string, then Perl::Review reverts
to its factory setup and all Policy modules that are distributed with
C<Perl::Review> will be loaded.  See L<"CONFIGURATION"> for more
information.

B<-priority> is the maximum priority value of Policies that should be
loaded from the configuration file. 1 is the "highest" priority, and
all numbers larger than 1 have "lower" priority.  Only Policies that
have been configured with a priority value less than or equal to
C<$N> will not be applied.  For a given C<-profile>, increasing
C<$N> will result in more violations.  See L<"CONFIGURATION"> for more
information.

=back

=head1 METHODS

=over 8

=item add_policy( $module_name, %args )

Registers a policy with this Review engine.  The policy name should be
a string that matches the name of a L<Perl::Review::Policy> subclass
module.  The C<'Perl::Review::Policy'> portion of the name can be
omitted for brevity.  The engine will attmept to load the module and
instantiate the subclass, passing C<%args> to the constructor.  See
the documentation for the relevant Policy module for a description of
the arguments it supports.

If it the module fails to load or cannot be instantiated, it will
throw a warning and return a false value.  Otherwise, it returns a
reference to this Review engine.

=item review_code( $source_code || $filename )

Runs the C<$source_code> (as SCALAR ref) or C<$filename> through the
Perl::Review engine using all the policies that have been registered
with this engine.  Returns a list of L<Perl::Review::Violation>
objects for each violation of the registered policies.  If there are
no violations, returns an empty list.

=back

=head1 CONFIGURATION

The default configuration file is called F<.perlreviewrc> and it lives
in your home directory.  If this file does not exist and the
C<-profile> option is not given to the constructor, Perl::Review
defaults to its factory setup, which means that all the policies that
are distributed with Perl::Review will be applied.

The format of the configuration file is a series of named sections
that contain key-value pairs separated by ':' or '='.  Comments
should start with '#' and can be placed on a separate line or after
the name-value pairing if you desire.  The general recipe is a series
of sections like this:

    [PolicyModuleName]
    priority = 1
    arg1 = value1
    arg2 = value2

The C<PolicyModuleName> should be the name of module that implements
the policy you want to use.  The module should be a subclass of
L<Perl::Review::Policy>.  For brevity, you can ommit the
C<'Perl::Review::Policy'> part of the module name.

The C<priority> should be the level of importance you wish to assign
this policy.  1 is the "highest" priority level, and all numbers
greater than 1 have increasingly "lower" priority.  Only those
policies with a priority less than or equal to the C<priority> value
given to the Perl::Review constructor will be applied.  The priority
can be an arbitrarily large positive integer.  If the priority is not
defined, it defaults to 1.

The remaining key-value pairs are configuration parameters for that
specific Policy and will be passed into the constructor of the
L<Perl::Review::Policy> subclass.  The constructors for most Policy
modules do not support arguments, and those that do should have
reasonable defaults.  See the documentation on the appropriate Policy
module for more details.

By default, all the policies that are distributed with Perl::Review
are applied.  Rather than assign priority levels to each one, you can
simply "turn off" a Policy by appending a '-' to the name of the
module in the config file.  In this manner, the Policy will never be
applied, regardless of the C<-priority> given to the Perl::Review
constructor.


A simple configuration might look like this:

    #--------------------------------------------------------------
    # These are really important, so always apply them

    [RequirePackageStricture]
    priority = 1

    [RequirePackageWarnings]
    priority = 1

    #--------------------------------------------------------------
    # These are less important, so only apply when asked

    [ProhibitOneArgumentBless]
    priority = 2

    [ProhibitDoWhileLoops]
    priority = 2

    #--------------------------------------------------------------
    # I don't agree with these, so never apply them

    [-ProhibitMixedCaseVars]
    [-ProhibitMixedCaseSubs]

=head1 THE POLICIES

The following Policy modules are distributed with Perl::Review.
The Policy modules have been categorized according to the table of
contents in Damian Conway's book B<Perl Best Practices>.  Since most
coding standards take the form "do this..." or "don't do that...", I
have adopted the convention of naming each module C<RequireSomething>
or C<ProhibitSomething>.  See the documentation of each module for
it's specific details.

L<Perl::Review::Policy::BuiltinFunctions::ProhibitStringyEval>

L<Perl::Review::Policy::BuiltinFunctions::ProhibitStringyGrep>       

L<Perl::Review::Policy::BuiltinFunctions::ProhibitStringyMap>

L<Perl::Review::Policy::CodeLayout::RequireTidyCode>

L<Perl::Review::Policy::ControlStructures::ProhibitPostfixControls>

L<Perl::Review::Policy::InputOutput::ProhibitBacktickOperators>

L<Perl::Review::Policy::Modules::ProhibitMultiplePackages>

L<Perl::Review::Policy::Modules::ProhibitRequireStatements> 

L<Perl::Review::Policy::Modules::ProhibitSpecificModules>

L<Perl::Review::Policy::Modules::ProhibitUnpackagedCode>

L<Perl::Review::Policy::NamingConventions::ProhibitMixedCaseSubs>

L<Perl::Review::Policy::NamingConventions::ProhibitMixedCaseVars>

L<Perl::Review::Policy::Subroutines::ProhibitSubroutinePrototypes>

L<Perl::Review::Policy::TestingAndDebugging::RequirePackageStricture>

L<Perl::Review::Policy::TestingAndDebugging::RequirePackageWarnings>

L<Perl::Review::Policy::ValuesAndExpressions::ProhibitConstantPragma>

L<Perl::Review::Policy::ValuesAndExpressions::ProhibitEmptyQuotes>

L<Perl::Review::Policy::ValuesAndExpressions::ProhibitInterpolationOfLiterals>

L<Perl::Review::Policy::ValuesAndExpressions::ProhibitNoisyQuotes>

L<Perl::Review::Policy::ValuesAndExpressions::RequireInterpolationOfMetachars>

L<Perl::Review::Policy::ValuesAndExpressions::RequireQuotedHeredocTerminator>

L<Perl::Review::Policy::ValuesAndExpressions::RequireUpperCaseHeredocTerminator>

L<Perl::Review::Policy::Variables::ProhibitLocalVars>

L<Perl::Review::Policy::Variables::ProhibitPackageVars>

L<Perl::Review::Policy::Variables::ProhibitPunctuationVars>

=head1 CREDITS

Adam Kennedy - For creating L<PPI>

Damian Conway - For writing B<Perl Best Practices>

Sharon, my wife - For putting up with my all-night code sessions

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.
