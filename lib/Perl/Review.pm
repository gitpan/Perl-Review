#   $Source: /cvs/asgus/tools/perlreview/lib/Perl/Review.pm,v $
# $Revision: 1.6 $
#     $Date: 2005/08/27 00:42:48 $

package Perl::Review;

use strict;
use warnings;
use base 'Exporter';
use English qw(-no_match_vars);
use PPI;

our @EXPORT_OK = qw(perlreview);
our $VERSION   = '0.01';

#---------------------------------------------------------
# Declare rules to be reviewed.  Each has a description,
# a PBB citiation or explanatory message, and a code 
# reference that returns all the nodes that violate the rule.
my @rules = (
    {
        desc => q{Code before 'package' declaration},
        code => \&code_before_package,
        msg  => q{Violates encapsulation},
    },
    {
        desc => q{Mixed-case subroutine name},
        code => \&mixed_case_sub_names,
        cite => [44],
    },
    {
        desc => q{Mixed-case variable names},
        code => \&mixed_case_var_names,
        cite => [44],
    },
    {
        desc => q{Subroutine prototypes used},
        code => \&prototyped_subs,
        cite => [194],
    },
    {
        desc => q{Variable declared as 'local'},
        code => \&local_declarations,
        cite => [73],
    },
    {
        desc => q{Punctuation variable used},
        code => \&punctuation_variables,
        cite => [79],
    },
    {
        desc => q{Useless interpolation of literal string},
        code => \&useless_interpolations,
        cite => [51],
    },
    {
        desc => q{Literal string may require interpolation},
        code => \&needed_interpolations,
        cite => [51],
    },
    {
        desc => q{Loop break without a label},
        code => \&break_without_label,
        cite => [129],
    },
    {
        desc => q{Bad heredoc terminator},
        code => \&bad_heredoc_terminator,
        cite => [ 62, 64 ],
    },
    {
        desc => q{Pragma 'use constant' used},
        code => \&use_constant,
        cite => [55],
    },
    {
        desc => q{Stricture is disabled},
        code => \&no_strict,
        cite => [429],
    },
    {
        desc => q{Warnings are disabled},
        code => \&no_warnings,
        cite => [431],
    },
    {
        desc => q{Backtick operator used},
        code => \&backtick_operations,
        msg  => q{Use IPC::Open3 instead},
    },
    {
        desc => q{Reference to symbol in another package},
        code => \&symbols_in_other_packages,
        msg  => q{Violates encapsulation},
    },
    {
        desc => q{String form of 'grep'},
        code => \&string_form_grep,
        cite => [169],
    },
    {
        desc => q{String form of 'map'},
        code => \&string_form_map,
        cite => [169],
    },
    {
        desc => q{String form of 'eval'},
        code => \&string_form_eval,
        cite => [161]
    },
    {
        desc => q{Postfix form of 'until'},
        code => \&postfix_until,
        cite => [96],
    },
    {
        desc => q{Postfix form of 'unless'},
        code => \&postfix_unless,
        cite => [96],
    },
    {
        desc => q{Use of 'require' declaration},
        code => \&require_declarations,
        msg  => q{Use 'use' declaration instead},
    },
    {
        desc => q{Code before stricture is enabled},
        code => \&use_strict,
	cite => [429],
    },
    {
        desc => q{Code before warnings are enabled},
        code => \&use_warnings,
	cite => [431],
    },
    {
        desc => q{Multiple 'package' declarations per file},
        code => \&multiple_packages,
	msg  => q{Limit to 1},
    },
    {
        desc => q{Literal number used in expression},
        code => \&literals_in_expression,
	msg  => q{Use a named variable instead},
    },
    {
        desc => q{Noisy string is hard to read},
        code => \&noisy_strings,
	cite => [0],
    },
    {
        desc => q{Bareword file handle opened},
        code => \&open_barewords,
	cite => [0],
    },
    {
        desc => q{One-argument form of 'bless'},
        code => \&one_argument_bless,
	cite => [0],
    },
    {
        desc => q{Two-argument form of 'open'},
        code => \&two_argument_open,
	cite => [0],
    }
);

#-------------------------------------------------------------------
# Some static strings
my $NO_VIOLATIONS = "Congratulations! No violations were found.\n";

#-------------------------------------------------------------------
# Regex for matching mixed-case symbols
my $all_noise_rx  = qr/ \A \W* \z /x;                    #for thing like "'"
my $mixed_case_rx = qr/ [A-Z][a-z] | [a-z][A-Z]      /x; #for MixedCaseWords
my $heredoc_rx    = qr/ \A << ["|'] [A-Z_]+ ['|"] \z /x; #All CAPS, with quotes


#-------------------------------------------------------------------
# Some variables to improve readability
my $COMMA_SPACE = q{, };
my $SEMI_COLON  = q{;};
my $PERIOD      = q{.};
my $COMMA       = q{,};


#====================================================================
# Main entry point here
sub perlreview {

    my $file = shift;
    
    #Read input from STDIN if a file name is not proivded.
    #This probably means we're being called from and editor.

    if(! defined($file) ){
	local $RS = undef; #Slurp mode
	my $code = <STDIN>;
	$file = \$code;
    }

    # Parse the code and save location of each token;
    my $doc = PPI::Document->new($file) || die "Can't parse '$file'";
    $doc->index_locations();

    # Review the code and print report
    my @messages = review( $doc, @rules );
    print $_->{msg} for @messages;
    my $msg_count = @messages;

    # Append extra reporting info
    if ($msg_count){
	print "Total violations: $msg_count\n";
    }
    else {
	warn $NO_VIOLATIONS;
    }

    return $msg_count;
}
# End of main sub
#====================================================================


#--------------------------------------------------------------------
# Apply rules and print report
sub review {

    my ( $doc, @rules ) = @_;
    my @messages = ();

    for my $rule_ref (@rules) {

        my $desc     = $rule_ref->{desc};
        my $code_ref = $rule_ref->{code};

        ### Generate message for each rule violation
        for my $match ( &$code_ref($doc) ) {
            next if !defined $match;
            my ( $line, $col ) = @{ $match->location() };
            my $msg = "$desc at line $line, column $col.";

            ### Append description or citation
            if ( my $page_ref = $rule_ref->{cite} ) {
                my $page = @{$page_ref} > 1 ? 'pages ' : 'page ';
                $page .= join( $COMMA_SPACE, @{$page_ref} );
                $msg .= "  See $page of PBP";
            }
            else {
                my $explain = $rule_ref->{msg};
                $msg .= "  $explain";
            }

            ### Append period, if needed
            $msg .= $PERIOD if $msg !~ m{\.\z}x;

            ### Accumulate messages to be sorted later
            push @messages, { msg => "$msg\n", at => "$line.$col" };
        }
    }
    #Sort messages by their location in the file
    return sort { $a->{at} <=> $b->{at} } @messages;
}

#----------------------------------------------------
# Find first code that appears before a 'package'
# declaration.  Code must be in an explicit namespace
sub code_before_package {
    my $doc = shift;
    my $match = $doc->find_first( sub { $_[1]->significant() } ) || return;
    return $match->isa('PPI::Statement::Package') ? () : ($match);
}

#--------------------------------------------------
# Find subroutine  names that are mixedCase. Names
# like 'BGI_fund' are allowed, but 'BGIfund' is not.
sub mixed_case_sub_names {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Statement::Sub') || return;
    my @matches   = grep { $_->name() =~ $mixed_case_rx } @{$nodes_ref};
    return @matches;
}

#--------------------------------------------------
# Find all variable names that are mixedCase. Names
# like 'BGI_fund' are allowed, but 'BGIfund' is not.
sub mixed_case_var_names {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Statement::Variable') || return;
    my @matches  = grep { _match_var_names( $_, $mixed_case_rx ) } @{$nodes_ref};
    return @matches;
}

#--------------------------------------------------
# Helper sub for matching variable names.
sub _match_var_names {
    my ( $node, $regex ) = @_;
    return grep { $_ =~ $regex } $node->variables();
}

#-------------------------------------------------
# Find all subroutines that are prototyped.
sub prototyped_subs {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Statement::Sub') || return;
    my @matches   = grep { $_->prototype() } @{$nodes_ref};
    return @matches;
}

#-------------------------------------------------------
# Find all uses of 'local'.  This can be allowed for
# some special globals, but is generally bad practice.
sub local_declarations {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Statement::Variable') || return;
    my @matches   = grep { $_->type() eq 'local' } @{$nodes_ref};
    return @matches;
}

#--------------------------------------------------------
# Find all usage of magical punctuation variables, such
# as $" $> $< etc.  You should 'use English' instead
sub punctuation_variables {
    my $doc     = shift;
    my $matches = $doc->find('PPI::Token::Magic') || return;

    #Filter out $_ and @_.  These are common enough to allow.
    return grep { $_ !~ m{\A [\$\@]_ \z}x } @{$matches};

}

#--------------------------------------------------------
# Find all awkward-looking strings like ',' or "".
sub noisy_strings {
    my $doc         = shift;
    my $doubles_ref = $doc->find('PPI::Token::Quote::Double') || [];
    my $singles_ref = $doc->find('PPI::Token::Quote::Single') || [];
    my @matches =  ( @{$doubles_ref}, @{$singles_ref} );
    return grep { $_ =~ $all_noise_rx } @matches;
}

#--------------------------------------------------------
# Find all double-quoted strings that don't seem to have
# any interpolated variables in them.
sub useless_interpolations {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Token::Quote::Double') || return;
    my @matches   = grep { !_has_interpolation($_) } @{$nodes_ref};
    return @matches;
}

#-------------------------------------------------------
# Find all single-quoted strings that do seem to have
# interpolated variables in them (things with $ or @)
sub needed_interpolations {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Token::Quote::Single') || return;
    my @matches   = grep { _has_interpolation($_) } @{$nodes_ref};
    return @matches;
}

#--------------------------------------------------------
# Helper sub to find strings that may need interpolation
sub _has_interpolation {
    my $node = shift || return;
    return $node =~ m{(?<!\\)[\$\@]}x           #Contains unescaped $ or @
	|| $node =~ m{\\[tnrfae0xcNLuLUEQ]}x;   #Containts escaped metachars
}

#------------------------------------------------------
# Find all loop breaks that don't have an explicit label
sub break_without_label {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Statement::Break') || return;
    my @matches   = ();
    for my $node ( @{$nodes_ref} ) {
        if ( $node->first_element() =~ m{next|last|redo|} ) {

            #Not working yet...
            #push @matches, $node;
        }
    }
    return @matches;
}

#-----------------------------------------------------
# Find all HEREDOC terminators with bad names.  All
# HEREDOC terminators should be quoted and in ALL CAPS
sub bad_heredoc_terminator {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Token::HereDoc') || return;
    my @matches   = grep { $_ !~ $heredoc_rx } @{$nodes_ref};
    return @matches;
}

#------------------------------------------------------
# Find all literal numbers that are not used in assignments.
# Such numbers should be put in well-named vars instead
sub literals_in_expression {
    my $doc = shift;
    my $nodes_ref = $doc->find('PPI::Token::Number') || return;
    return #grep { $_->sprevious_sibling() ne '='} @{$nodes_ref}; 
}

#------------------------------------------------------
# Find all one-argument forms of 'bless'
sub one_argument_bless {
    my $doc = shift;
    my $funcs_ref = find_function_call($doc, 'bless') || return;
    my @matches = ();
    foreach my $func ( @{$funcs_ref} ){
	my ($node, $args) = each %{$func};
	push(@matches, $args->[0]) if scalar @{$args} == 1;
    }
    return @matches;
}

#------------------------------------------------------
# Find all two-argument forms of 'open'
sub two_argument_open {
    my $doc = shift;
    my $funcs_ref = find_function_call($doc, 'open') || return;
    my @matches = ();
    foreach my $func ( @{$funcs_ref} ){
	my ($node, $args) = each %{$func};
	push(@matches, $args->[0]) if scalar @{$args} == 2;
    }
    return @matches;
}

#------------------------------------------------------
# Find the second 'package' declaration.  Generally,
# you should only have one per file.
sub multiple_packages {
    my $doc = shift;
    my $nodes_ref = $doc->find('PPI::Statement::Package') || return;
    return @{$nodes_ref} > 0 ? ($nodes_ref->[1]) : ();
}

#------------------------------------------------------
# Find all 'use constant' pragmas
sub use_constant {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Statement::Include') || return;
    my @matches   =
      grep { $_->type() eq 'use' && $_->pragma() eq 'constant' } @{$nodes_ref};
    return @matches;
}

#-------------------------------------------------------
# 'use strict' must come before all statements other 
# than 'use', 'require', or 'package'  statements.
sub use_strict {
    my $doc = shift;
    my $other_stmnt  = $doc->find_first( \&helper3 ) || return;
    my $strict_stmnt = $doc->find_first( \&helper1 ) || $other_stmnt;
    my $other_at  = $other_stmnt->location()->[0];
    my $strict_at = $strict_stmnt->location()->[0];
    return ($other_at <= $strict_at ? $other_stmnt : ());
}


#-------------------------------------------------------
# 'use warnings' must come before all statements other 
# than 'use', 'require', or 'package'  statements.
sub use_warnings {
    my $doc = shift;
    my $other_stmnt  = $doc->find_first( \&helper3 )   || return;
    my $warnings_stmnt = $doc->find_first( \&helper2 ) || $other_stmnt;
    my $other_at  = $other_stmnt->location()->[0];
    my $warnings_at = $warnings_stmnt->location()->[0];
    return ($other_at <= $warnings_at ? $other_stmnt : ());
}

#====================================================================
# These helper classes are used by use_strct() and use_warnings(),
# which have slightly more complicated rules so we have factord part
# of it out.  These helpers are ust used to find certain types of 
# Elements in the document tree.

#-------------------------------------------------
# Return true for any 'use strict' statement.
sub helper1 {

    my ($doc, $node) = @_;
    return ($node->isa('PPI::Statement::Include') 
	    && $node->type() eq 'use' 
	    && $node->pragma() eq 'strict'
	    );
}
#------------------------------------------------
# Return true for any 'use warnings' statement.
sub helper2 {

    my ($doc, $node) = @_;
    return ($node->isa('PPI::Statement::Include') 
	    && $node->type() eq 'use' 
	    && $node->pragma() eq 'warnings'
	    );
}

#------------------------------------------------
#Retrun true for any Statement subclass other than Include and Package
sub helper3 {
    my ($doc, $node) = @_;
    return ($node->isa('PPI::Statement')
	    && ! ($node->isa('PPI::Statement::Include')
		  || $node->isa('PPI::Statement::Package'))  
	    );
}
#=======================================================================
    
#------------------------------------------------------
# Find all 'no strict' pragmas
sub no_strict {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Statement::Include') || return;
    my @matches   =
      grep { $_->type() eq 'no' && $_->pragma() eq 'strict' } @{$nodes_ref};
    return @matches;
}

#------------------------------------------------------
# Find all 'no warnings' pragmas
sub no_warnings {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Statement::Include') || return;
    my @matches   =
      grep { $_->type() eq 'no' && $_->pragma() eq 'warnings' } @{$nodes_ref};
    return @matches;
}

#------------------------------------------------------
# Find all backticks.  Its better to use open() or
# open3() and capture all the output from the command.
sub backtick_operations {
    my $doc = shift;
    my $matches = $doc->find('PPI::Token::QuoteLike::Backtick') || return;
    return @{$matches};
}

#------------------------------------------------------
# Find reference to symbols in other packaages. This
# is legal, but tends to violate encapsulation
sub symbols_in_other_packages {
    my $doc       = shift;
    my $nodes_ref = $doc->find('PPI::Token::Symbol') || return;
    my @matches   = grep { $_->canonical() =~ /::/ } @{$nodes_ref};
    return @matches;
}

#------------------------------------------------------
#Find string form of map (e.g. map "$exp", @list;
#The block form is preferred (e.g. map {$expr} @list
sub string_form_map {
    my $doc       = shift;
    my @matches   = ();
    my $nodes_ref = find_keywords( $doc, 'map' ) || return;
    return
      grep { !$_->snext_sibling->isa('PPI::Structure::Block') } @{$nodes_ref};
}

#------------------------------------------------------
#Find string form of grep (e.g. grep "$exp", @list;
#The block form is preferred (e.g. grep {$expr} @list
sub string_form_grep {
    my $doc       = shift;
    my @matches   = ();
    my $nodes_ref = find_keywords( $doc, 'grep' ) || return;
    return
      grep { !$_->snext_sibling->isa('PPI::Structure::Block') } @{$nodes_ref};
}

#------------------------------------------------------
#Find string form of grep (e.g. eval "$exp", @list;
#The block form is preferred (e.g. eval {$expr} @list
sub string_form_eval {
    my $doc       = shift;
    my @matches   = ();
    my $nodes_ref = find_keywords( $doc, 'eval' ) || return;
    return
      grep { !$_->snext_sibling->isa('PPI::Structure::Block') } @{$nodes_ref};
}

#------------------------------------------------------
#Find postfix form of 'until'
sub postfix_unless {
    my $doc = shift;
    my $nodes_ref = find_postfix_modifiers( $doc, 'until' ) || return;
    return @{$nodes_ref};
}

#------------------------------------------------------
#Find postfix form of 'unless'
sub postfix_until {
    my $doc = shift;
    my $nodes_ref = find_postfix_modifiers( $doc, 'unless' ) || return;
    return @{$nodes_ref};
}

#-------------------------------------------------------
#Find 'open' with bareword filehandles
sub open_barewords {
    my $doc = shift;
    my $funcs_ref = find_function_call( $doc, 'open' ) || return;
    my @matches = ();
    foreach my $func ( @{$funcs_ref} ){
	my ($node, $args) = each %{$func};
	push(@matches, $args->[0]) if $args->[0]->isa('PPI::Token::Word');
    }
    return @matches;
}


#-------------------------------------------------------
# Finds a keyword with a given name
sub find_keywords {
    my ( $doc, $func ) = @_;
    my $nodes_ref = $doc->find('Token::Word') || return;
    my @matches = grep { $_ eq $func } @{$nodes_ref};
    return @matches ? \@matches : undef;
}

#-------------------------------------------------------
# Finds things that look like function calls and
# returns them with the arguments parsed into a list
sub find_function_call {

    my ( $doc, $func ) = @_;
    
    #Find barewords that match the function name, and
    #then parse the arguments for that function
    my $matches = find_keywords($doc, $func) || return;
    my @results = map { {$_ => parse_args($_)} } @{$matches};
    return \@results;
}


#-------------------------------------------------------
# Given a PPI element that is assumed to be the function
# call, parses the remainder of the expression into a 
# list of arguments that to be passed in.
sub parse_args {

    my $node = shift;
    my @args = ();

    #When called with parens, the arguments are in a sibling list
    #strucutre. But when called without parens, the arguments are
    #basically everything after the keyword and before the semicolon

    my $sib = $node->snext_sibling() || return;
    if ($sib->isa('PPI::Structure::List')) {

	#Within a Structure::List, the contents
	#are the children of a single Expression
	my $expr = $sib->schild(0);
	@args = $expr ? $expr->children() : ();  #Watch for empty lists!
    }
    else {

	#Without parens, the args are everything that 
	#comes after the bareword (i.e. subroutine name) 
	while(my $snext = $node->snext_sibling()){
	    push @args, $snext; #Put node on stack
	    $node = $snext;     #Move iterator forward
	}
    }
    return split_list(@args);
}


#----------------------------------------------------------
# Splits sereis of comma-delimited PPI::Elements into a list 
sub split_list {

    my @nodes = @_;
    my @elements = ();

    for my $node (@nodes) {

	#Skip whitespace
	next if $node->isa('PPI::Token::Whitespace');

	#Skip over the commas
	next if $node->isa('PPI::Token::Operator') 
	    && $node eq $COMMA;
	
	#Quit if we hit the statement terminator 
	last if $node->isa('PPI::Token::Structure')
	    && $node eq $SEMI_COLON;
		    
	push @elements, $node;
    }
    return \@elements;
}

#------------------------------------------------------------
# Find things that look like postfix mods (until, unless, for)
# PPI treats these differently from regular conditionals
sub find_postfix_modifiers {
    my ( $doc, $mod ) = @_;
    my $nodes_ref = find_keywords( $doc, $mod ) || return;
    my @matches = grep { $_->sprevious_sibling() } @{$nodes_ref};
    return \@matches;
}

#------------------------------------------------------------
# Find all 'require' declarations.  Except in rare cases,
# the 'use' declaration is better.
sub require_declarations {
    my $doc       = shift;
    my $nodes_ref = $doc->find('Statement::Include') || return;
    my @matches   =
      grep { $_->type() eq 'require' } @{$nodes_ref};
    return @matches;
}

1;

__END__


Things TODO:
Loops without labels
until structures
unless structures
ambiguous names
return with undef
do...while loops
long subroutines
subs with many args

