use strict;
use warnings;
use Module::Build;

my @scripts;
open (fd, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<fd>){
  chomp;
  push @scripts, $_ if /^(scripts)\//;
}

my %cgi_scripts;
open (fd, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<fd>){
  chomp;
  $cgi_scripts{$_}=$_ if /^(cgi)\//;
}

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
    script_files=>\@scripts,
    cgi_files=>\%cgi_scripts,
    install_path => { cgi =>"blib/cgi/" },
    add_to_cleanup      => [ 'Util-Properties-*' ],
);
$builder->add_build_element('cgi');
$builder->create_build_script();
