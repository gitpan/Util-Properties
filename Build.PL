use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Util::Properties',
    license             => 'gpl',
    dist_author         => 'Alexandre Masselot <alexandre.masselot@genebio.com>',
    dist_version_from   => 'lib/Util/Properties.pm',
    requires => {
#		 'Test::More' => 0,
		 'IO::All' => 0,
		 'LockFile::Simple' => 0,
		 'Object::InsideOut' => 0,
		 'Digest::MD5::File' => 0,
		},
    add_to_cleanup      => [ 'Util-Properties-*' ],
);

$builder->create_build_script();
