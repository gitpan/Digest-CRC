use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Digest::CRC',
    'VERSION_FROM' => 'lib/Digest/CRC.pm', # finds $VERSION
    'PL_FILES' => {},
);
