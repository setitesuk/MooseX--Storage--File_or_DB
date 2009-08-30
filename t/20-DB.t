use strict;
use warnings;
use Carp;
use English qw{-no_match_vars};
use Test::More 'no_plan';#tests => ;
use Test::Exception;
use lib qw{t t/lib};
use util;
use DateTime;

BEGIN {
  use_ok('MooseX::Storage::File_or_DB');
  use_ok('DB_test');
}

my $util = util->new({
  dbname => q{test_db},
});

{
  my $dbtest = DB_test->new();
  isa_ok($dbtest, q{DB_test}, q{$dbtest});
  throws_ok { $dbtest->write_to_database();  } qr{no[ ]dbh[ ]found}, q{no database handle provided - write};
  throws_ok { $dbtest->read_from_database(); } qr{no[ ]dbh[ ]found}, q{no database handle provided - read};
}
{
  $util->create_test_database();
  my $dbtest = DB_test->new({
    dbh => $util->dbh(),
    col_a => q{Hello},
    col_b => 3,
    col_c => q{World},
    col_d => q{Goodbye},
  });
  lives_ok { $dbtest->write_to_database(); } q{saved out to the db ok};
  my $new_dbtest = DB_test->new({
    dbh => $util->dbh(),
    col_index => 1,
  });
  lives_ok { $dbtest->read_from_database(); } q{read from the db ok}
}
1;