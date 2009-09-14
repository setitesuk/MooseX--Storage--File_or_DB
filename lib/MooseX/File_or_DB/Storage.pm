#############
# Created By: setitesuk
# Created On: 2009-08-28

package MooseX::File_or_DB::Storage;
use Moose;
use MooseX::InsideOut;
use Carp;
use English qw{-no_match_vars};
use Readonly;

use MooseX::Storage;
   with (Storage( traits => ['DisableCycleDetection', 'OnlyWhenBuilt'], 'format' => 'JSON', 'io' => 'File')); # ensures  that we can still export to a JSON string

our $VERSION = 0.4;

has q{dbh} => ( isa => q{Object}, is => q{rw}, metaclass => 'DoNotSerialize', predicate => q{has_dbh} );

sub write_to_database {
  my ($self) = @_;
  if (!$self->has_dbh()) {
    croak q{no dbh found};
  }
  my $dbh = $self->dbh();
  my $params = $self->_determine_db_query_params();

  my $fields_string = join q{,}, @{$params->{fields}};
  my $val_spaces_string = join q{,}, @{$params->{val_spaces}};

  #######
  # will update a row if there is a primary key column and populated
  my $primary_key;
  eval { $primary_key = $self->primary_key(); } or do {}; # silently fails if there is no primary key method
  if ($primary_key && $self->$primary_key()) {
    return $self->_update_row($params);
  }

  eval {
    my $insert_statement = qq{INSERT INTO $params->{table}($fields_string) VALUES ($val_spaces_string)};
    $dbh->do($insert_statement, {}, @{$params->{values}});
    $dbh->commit();
  } or do {
    croak $EVAL_ERROR;
  };

  return 1;
}

sub read_from_database {
  my ($self) = @_;
  if (!$self->has_dbh()) {
    croak q{no dbh found};
  }
  my $dbh = $self->dbh();
  my $params = $self->_determine_db_query_params();
  $params->{dbh} = $dbh;

  my $info = $self->_db_lookup($params);#results[0];

  foreach my $key (sort keys %{$info}) {
    next if $key eq q{class};
    if ($key eq $self->primary_key()) {
      $self->_set_primary_key($info->{$key});
      next;
    }
    $self->$key($info->{$key});
  }

  return 1;
}

sub restore_from_database {
  my ($class, $args) = @_;
  my $dbh = $args->{dbh};
  if (!$dbh) {
    croak q{no dbh found};
  }
  delete $args->{dbh};
  my $table = $class;
  $table =~ s/::/_/gxms;

  my (@fields, @values);

  foreach my $field (keys %{$args}) {
    push @fields, $field;
    push @values, $args->{$field};
  }

  my $arg_refs = {
    dbh    => $dbh,
    table  => $table,
    fields => \@fields,
    values => \@values,
  };

  return $class->unpack($class->_db_lookup($arg_refs));
}


################
# Private methods

##############
# only used in the case where a row might need updating - probably if you intend to use your subclass as a model backend to an application
sub _update_row {
  my ($self, $params) = @_;
  my $dbh = $self->dbh();
  my $values = $params->{values};

  eval {
    my $update_statement = qq{UPDATE $params->{table} SET };

    my $update_string = join q{ = ?, }, @{$params->{fields}};
    $update_statement .= $update_string . q{ = ? };

    my $primary_key = $self->primary_key();

    $update_statement .= qq{WHERE $primary_key = ?};

    $dbh->do( $update_statement, {}, (@{$values}, $self->$primary_key()) );
    $dbh->commit();
  } or do {
    croak $EVAL_ERROR;
  };

  return 1;
}

##############
# does the select lookup
sub _db_lookup {
  my ($self, $args) = @_;
  my $dbh    = $args->{dbh};
  my $fields = $args->{fields};
  my $values = $args->{values};
  my $table  = $args->{table};


  my $query = qq{SELECT * FROM $table WHERE };
  my $count = 0;
  foreach my $field (@{$fields}) {
    if ($count != 0) {
      $query .= q{AND };
    }
    $count++;
    $query .= qq{$field = ? };
  }

  my $sth = $dbh->prepare($query);
  $sth->execute(@{$values});
  my @results;
  while (my $href = $sth->fetchrow_hashref()) {
    push @results, $href;
  }

  if (!scalar @results) {
    croak q{No data obtained from database};
  }

  if (scalar @results > 1) {
    carp q{More than one result from the database, only populating with the first returned result};
  }

  return $results[0];
}

#############
# uses the pack option to construct the database columns, and the values to be used
sub _determine_db_query_params {
  my ($self) = @_;
  my $href = $self->pack();
  my (@fields, @values, @val_spaces);
  my $table;

  foreach my $field (sort keys %{$href}) {
    my $value = $href->{$field};
    if ($field eq q{__CLASS__}) {
      $field = q{class};
      $table = $value;
      $table =~ s/::/_/gxms;
      $table =~ s/-\d+\z//gxms;
      $table =~ tr/[A-Z]/[a-z]/;
    }
    push @fields, $field;
    push @values, $value;
    push @val_spaces, q{?};
  }

  return {
          table => $table,
          fields => \@fields,
          values => \@values,
          val_spaces => \@val_spaces,
         };
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

MooseX::File_or_DB::Storage

=head1 VERSION

0.3

=head1 SYNOPSIS

  package MyClass;
  use Moose;
  extends q{MooseX::File_or_DB::Storage};

  has q{xxx_id} => (isa => q{Int}, is => q{ro}, writer => q{_set_primary_key}); # if your table has a unique primary key, set it as this
  ... your attributes here - these should be rw, not ro ...

  sub primary_key {  # if your table has a unique primary key, then add this method to be able to update a row with the write_to_database method
    my ($self) = @_;
    return q{xxx_id};
  }

  no Moose;
  __PACKAGE__->meta->make_immutable;
  1;

  my $myclass = MyClass->new({
    dbh => $oDBH, # this is optional (i.e. for read/write to a filesystem), but required if you intend to do database read/write
    ...
  });

  $myclass->write_to_database();
  $myclass->read_from_database(); # If you don't want to restore from the class method but would prefer to have the object instantiated first

or you can restore directly from the database

  my $myclass_from_db = MyClass->restore_from_database({
    dbh => $oDBH,
    ... # some fields which will should make a database lookup unique
  });

=head1 DESCRIPTION

(Previously, this was MooseX::Storage::File_or_DB)

Class for simply storing a Moose object out to database, but where each attribute is a table column, so it can undergo
ordinary database interrogation with SQL (however dirty that might be) or reinstantiated to the Moose object

The objective of this is that we won't overwrite the functionality of writing out to/reading in from a file either, so that
a choice can be made as to where the data may be (i.e. short term in FileSystem, but long term from a DataBase).

This extends the MooseX::Storage Class by adding further methods which can serialise out to a database that is connected
to using a dbh provided by you, which should be a handle from a DBI class.

This class makes use of MooseX::Storage.

For now, you need to have your own database schema which will reflect the object. This may change.
Each table must have a 'class' column, with VARCHAR(256) (256 or a value suitable for the length of the package name).
Each table should be named exactly the same as your package name, but with the double colon replace with a single underscore
and all capitals replaced with lower case letters

  i. e.  My::Class::To::Save - becomes - my_class_to_save

=head1 SUBROUTINES/METHODS

=head2 restore_from_database

handles generating the object from the database entry

  my $myclass_from_db = MyClass->restore_from_database({
    dbh => $oDBH,
    ... # some fields which will should make a database lookup unique
  });

This is the prefered method to obtain back from the database.

=head2 write_to_database

handles writing your object out to the database table, if you have a unique primary key, it will update the row instead, provided you
have the primary_key method to enable this

=head2 read_from_database

handles bringing your object back from the database table for this you need your unique primary key or
unique composite index fields to already be given, for the inevitable table lookup
This method is provided, but you should use Class->restore_from_database({args}) in preference. In later revisions, this may become deprecated.

=head2 primary_key

This should be defined in your sub class, and should return the attribute (column) name which will store the unique primary key value

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::InsideOut

=item MooseX::Storage

=item Carp

=item English -no_match_vars

=item Readonly

=back

=head1 INCOMPATIBILITIES

As of this time, subject to the information above, I know of no Incompatibilities, however, this does not mean
they don't exist. Please let me know if you find any

=head1 BUGS AND LIMITATIONS

As with any software, there are possibly a few bugs (or maybe more). If you find any, please let me know.
Also, I am open to any improvements, so please submit any patches you create. You can fork the source code
from http://github.com/setitesuk/MooseX--Storage--File_or_DB

=head1 AUTHOR

setitesuk

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2009 Andy Brown (setitesuk@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
