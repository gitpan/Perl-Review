use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Test::More qw(no_plan);

#-----------------------------------------------------
#Test modules for compilation, methods and inheritance

my @policy_modules = 
qw(BuiltinFunctions::ProhibitStringyEval
   BuiltinFunctions::ProhibitStringyGrep	       
   BuiltinFunctions::ProhibitStringyMap                    		       
   CodeLayout::RequireTidyCode                                   
   ControlStructures::ProhibitPostfixControls              		       
   InputOutput::ProhibitBacktickOperators                        
   Modules::ProhibitMultiplePackages                              
   Modules::ProhibitRequireStatements                      		       
   Modules::ProhibitSpecificModules                               
   Modules::ProhibitUnpackagedCode                         	       
   NamingConventions::ProhibitMixedCaseSubs                	       
   NamingConventions::ProhibitMixedCaseVars                       
   Subroutines::ProhibitSubroutinePrototypes               	       
   TestingAndDebugging::RequirePackageStricture                       
   TestingAndDebugging::RequirePackageWarnings             
   ValuesAndExpressions::ProhibitConstantPragma                 
   ValuesAndExpressions::ProhibitEmptyQuotes                   
   ValuesAndExpressions::ProhibitInterpolationOfLiterals         
   ValuesAndExpressions::ProhibitNoisyQuotes               
   ValuesAndExpressions::RequireInterpolationOfMetachars     
   ValuesAndExpressions::RequireQuotedHeredocTerminator    
   ValuesAndExpressions::RequireUpperCaseHeredocTerminator 
   Variables::ProhibitLocalVars                                   
   Variables::ProhibitPackageVars                          
   Variables::ProhibitPunctuationVars		           	       
   Variables::RequireLocalizedGlobalVars
);

for my $mod (@policy_modules) {

    #Test 'use'
    $mod = "Perl::Review::Policy::$mod";	
    use_ok($mod);

    #Test methods
    can_ok($mod, 'new');
    can_ok($mod, 'violations');
    
    #Test inheritance
    my $obj = $mod->new();
    isa_ok($obj, 'Perl::Review::Policy');
}

my @main_modules =
qw(Review
   Review::Config
   Review::Policy
   Review::Violation
);

for my $mod (@main_modules) {

    #Test 'use'
    $mod = "Perl::$mod";	
    use_ok($mod);

    #Test constructor
    can_ok($mod, 'new');
}

#-------------------------------------
# Test other methods
can_ok('Perl::Review', 'add_policy');
can_ok('Perl::Review::Violation', 'location');
can_ok('Perl::Review::Violation', 'description');
can_ok('Perl::Review::Violation', 'explanation');

