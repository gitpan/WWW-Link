use ExtUtils::MakeMaker;
WriteMakefile( NAME => "WWW-Link",
	       VERSION_FROM => "lib/WWW/Link.pm",
	       dist => {COMPRESS => "gzip",
			SUFFIX => "gz" },
#moved to linkcontroller   PREREQ_PM => { CDB_File::BiIndex=>0.026 },
	     );
