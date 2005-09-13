
use ExtUtils::MakeMaker;

WriteMakefile( NAME           => 'Perl::Review',
	       AUTHOR         => 'Jeffrey Thalhammer <thaljef@cpan.org>',
	       ABSTRACT_FROM  => 'lib/Perl/Review.pm',
	       VERSION_FROM   => 'lib/Perl/Review.pm',
	       EXE_FILES      => ['bin/perlreview'],
	       PREREQ_PM      => {'PPI' => '+1.0',
				  'Config::Std' => '0',
				  'File::Spec::Functions' => '0',
				  'List::MoreUtils' => 0,
				  'List::Util' => 0,
				  'Pod::Usage' => 0,
                                  'Test::More' => 0,
				  'FindBin' => 0,
			      }
);
