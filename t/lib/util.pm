#############
# $Id$
# Created By: setitesuk
# Mast Maintained By: $Author$
# Created On: 2009-08-29
# Last Changed On: $Date$
# $HeadURL$

package util;
use Moose;
use MooseX::InsideOut;
use Carp;
use English qw{-no_match_vars};
use Readonly;
use DBI;

Readonly::Scalar our $VERSION => do { my ($r) = q$LastChangedRevision: 5210 $ =~ /(\d+)/mxs; $r; };

has q{dbh}    => (isa => q{Object}, is => q{rw}, lazy_build => 1);
has q{dbname} => (isa => q{Str}, is => q{rw});
has q{db_schema} => (isa => q{Str}, is => q{rw}, default => q{test_schema.sql});

sub create_test_database {
  my ($self) = @_;
  my $db = q{t/data/} . $self->dbname();
  `rm -f $db`;
  my $db_schema = q{t/data/} . $self->db_schema();
  `cat $db_schema | sqlite3 $db`;
  return 1;
}

sub _build_dbh {
  my ($self) = @_;

  my $dsn = sprintf q(DBI:SQLite:dbname=%s),
	      q{t/data/} . $self->dbname     || q[];

  my $dbh;
  eval {
    $dbh = DBI->connect($dsn, q[], q[],
			  {RaiseError => 1,
			   AutoCommit => 0});
  } or do {
    croak qq[Failed to connect to $dsn:\n$EVAL_ERROR];
  };
  
  return $dbh;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

util

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Carp

=item English -no_match_vars

=item Readonly

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author$

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
