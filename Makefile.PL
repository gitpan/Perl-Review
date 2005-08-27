#   $Source: /cvs/asgus/tools/perlreview/lib/Perl/Review.pm,v $
# $Revision: 1.6 $
#     $Date: 2005/08/27 00:42:48 $

use ExtUtils::MakeMaker;

WriteMakefile( NAME      => 'Perl::Review',
	       AUTHOR    => 'Jeffrey Thalhammer <thaljef@cpan.org>',
	       ABSTRACT  => 'Critique Perl source code.',
	       PREREQ_PM => {'PPI' => '1.0'},
	       VERSION   => '0.1',
	       EXE_FILES => ['bin/perlreview']);

