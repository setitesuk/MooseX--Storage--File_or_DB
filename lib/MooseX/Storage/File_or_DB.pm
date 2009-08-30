#############
# Created By: setitesuk
# Created On: 2009-08-28

package MooseX::Storage::File_or_DB;
use Moose;
use MooseX::InsideOut;
use Carp;
use English qw{-no_match_vars};
use Readonly;

use MooseX::Storage;
   with (Storage( traits => ['DisableCycleDetection', 'OnlyWhenBuilt'], 'format' => 'JSON', 'io' => 'File')); # ensures  that we can still export to a JSON string

Readonly::Scalar our $VERSION => 0.1;

sub write_to_database {
  my ($self) = @_;
  if (!$self->has_dbh()) {
    croak q{no dbh found};
  }
  my $dbh = $self->dbh();
  my $href = $self->pack();

  if (!$href->{__CLASS__}) {
    croak q{No __CLASS__ found - is this actually an object?};
  }

  my (@fields, @values, @val_spaces);
  my $table;
  foreach my $field (keys %{$href}) {
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

  my $fields_string = join q{,}, @fields;
  my $val_spaces_string = join q{,}, @val_spaces;

  eval {
    my $insert_statement = qq{INSERT INTO $table($fields_string) VALUES ($val_spaces_string)};
    $dbh->do($insert_statement, {}, @values);
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
  my $href = $self->pack();
  my (@fields, @values, @val_spaces);
  my $table;
  foreach my $field (keys %{$href}) {
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

  my $query = qq{SELECT * FROM $table WHERE };
  my $count = 0;
  foreach my $field (@fields) {
    if ($count != 0) {
      $query .= q{AND };
    }
    $count++;
    $query .= qq{$field = ? };
  }
  my $sth = $dbh->prepare($query);
  $sth->execute(@values);
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

  my $info = $results[0];

  foreach my $key (%{$info}) {
    next if $key eq q{class};
    if ($key eq $self->primary_key()) {
      $self->_set_primary_key($info->{$key});
    }
    $self->$key($info->{$key});
  }

  return 1;
}



no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

MooseX::Storage::File_or_DB

=head1 VERSION

0.1

=head1 SYNOPSIS

  package MyClass;
  use Moose;
  extends q{MooseX::Storage::File_or_DB};

  has q{dbh} => ( isa => q{Object}, is => q{ro}, metaclass => 'DoNotSerialize', predicate => q{has_dbh} );
  ... your other attributes here ...

  no Moose;
  __PACKAGE__->meta->make_immutable;
  1;

  my $myclass = MyClass->new({
    ...
  });

  $myclass->write_to_database();
  $myclass->read_from_database();

=head1 DESCRIPTION

Class for simply storing a Moose object out to database, but where each attribute is a table column, so it can undergo
ordinary database interrogation with SQL (however dirty that might be) or reinstantiated to the Moose object

The objective of this is that we won't overwrite the functionality of writing out to/reading in from a file either, so that
a choice can be made as to where the data may be (i.e. short term in FileSystem, but long term from a DataBase).

This extends the MooseX::Storage Class by adding further methods which can serialise out to a database that is connected
to using a dbh provided by you, which should be a handle from a DBI class.

This class makes use of MooseX::Storage, and it is vitally important that you ensure your dbh attribute is declared with
the metaclass => 'DoNotSerialize', or else Bad things will happen.

For now, you need to have your own database schema which will reflect the object. This may change.
Each table must have a 'class' column, with VARCHAR(256) (256 or a value suitable for the length of the package name).
Each table should be named exactly the same as your package name, but with the double colon replace with a single underscore
and all capitals replaced with lower case letters

  i. e.  My::Class::To::Save - becomes - my_class_to_save

=head1 SUBROUTINES/METHODS

=head2 write_to_database

handles writing your object out to the database table, if you have a unique primary key, it will update the row instead

=head2 read_from_database

handles bringing your object back from the database table for this you need your unique primary key or
unique composite index fields to already be given, for the inevitable table lookup

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

As with any software, there are possibly a few bugs (or maybe more). If you find any, please ley me know.
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
