use strict;
use warnings;
use Carp;
use English qw{-no_match_vars};
use Test::More 'no_plan';#tests => ;
use Test::Exception;
use lib qw{t t/lib};
use util;

BEGIN {
  use_ok('MooseX::File_or_DB::Storage');
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
  lives_ok { $dbtest->read_from_database(); } q{read from the db ok using params};
  is($dbtest->col_index(), 1, q{col_index read in});

  my $new_dbtest = DB_test->new({
    dbh => $util->dbh(),
    col_index => 1,
  });
  lives_ok { $new_dbtest->read_from_database(); } q{read from the db ok using a unique primary key};
  is($new_dbtest->col_a(), q{Hello}, q{col_a populated from database});
}

{
  my $dbtest = DB_test->new({
    dbh => $util->dbh(),
    col_index => 2,
  });
  throws_ok { $dbtest->read_from_database(); } qr{No[ ]data[ ]obtained[ ]from[ ]database}, q{croak as no rows found};
}

{
  my $dbtest = DB_test->new({
    dbh => $util->dbh(),
    col_a => q{Goodbye},
    col_b => 4,
    col_c => q{World},
    col_d => q{Hello},
  });
  lives_ok { $dbtest->write_to_database();  } q{saved out 2nd row ok};
  lives_ok { $dbtest->read_from_database(); } q{read from the db ok using params};
  is($dbtest->col_index(), 2, q{row 2});

  my $newdbtest = DB_test->new({
    dbh => $util->dbh(),
    col_c => q{World},
  });
  lives_ok { $newdbtest->read_from_database(); } q{read in when 2 rows returned};
  is($newdbtest->col_index(), 1, q{row 1 is given when 2 rows returned});
}

{
  my $dbtest_restore;
  lives_ok { $dbtest_restore = DB_test->restore_from_database({
    dbh => $util->dbh(),
    col_a => q{Goodbye},
  }); } q{generated from restore_from_database function};
  isa_ok($dbtest_restore, q{DB_test}, q{$dbtest_restore});
  is($dbtest_restore->col_b(), 4, q{col_b value has been accurately restored});

  my $json_string = $dbtest_restore->freeze();
  my $new_object = DB_test->thaw($json_string);
  isa_ok($new_object, q{DB_test}, q{thawed from JSON string ok});

  foreach my $attribute (qw{col_a col_b col_c col_d}) {
    is($new_object->$attribute(), $dbtest_restore->$attribute(), qq{$attribute correct});
  }

  lives_ok { $new_object->dbh($util->dbh()); } q{dbh passed into new object ok};
  lives_ok { $new_object->read_from_database(); } q{read from db ok};
  is($new_object->col_index(), 2, q{index ok});

  $new_object->col_a(q{Auf Weidersehn});
  lives_ok { $new_object->write_to_database(); } q{written to database};
}

{
  my $dbtest_restore;
  lives_ok { $dbtest_restore = DB_test->restore_from_database({
    dbh => $util->dbh(),
    col_a => q{Auf Weidersehn},
  }); } q{generated from row with Auf Weidersehn as update};
  is($dbtest_restore->col_index(), 2, q{got correct row});
}

1;