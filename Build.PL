use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
				 module_name         => 'MooseX::File_or_DB::Storage',
				 dist_author         => 'Andy Brown <setitesuk@gmail.com>',
				 dist_version        => 0.4,
				 dist_abstract       => q[module to add functions which will store out to a database as well as a file which contains a JSON string],
				 license             => 'perl',
				 requires            => {
				       'Moose'              => 0,
				       'MooseX::InsideOut'  => 0,
				       'MooseX::Storage'    => 0,
							 'English'            => '1.01',
							 'Carp'               => '1.02',
							 'DBI'                => '1.51',
							 'Config::IniFiles'   => '2.38',
							 'Readonly'           => '1.03',
							 'strict'             => 0,
							 'warnings'           => 0,
							},
				 build_requires      => {
							 'Test::Distribution' => '0',
							 'Test::Perl::Critic' => '0',
							 'Test::More'         => '0.8',
							 'Test::Exception'    => '0',
							 'DBD::SQLite'        => '0',
							},
				 build_recommends    => {
				       'Test::Kwalitee',
							},
				 create_makefile_pl  => 'passthrough',
				 script_files        => [qw()],
				);

$builder->create_build_script();
