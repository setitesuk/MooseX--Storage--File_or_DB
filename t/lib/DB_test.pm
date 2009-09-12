#############
# $Id$
# Created By: setitesuk
# Mast Maintained By: $Author$
# Created On: 2009-09-29
# Last Changed On: $Date$
# $HeadURL$

package DB_test;
use Moose;
use MooseX::InsideOut;
use Carp;
use English qw{-no_match_vars};
use Readonly;

extends qw{MooseX::File_or_DB::Storage};

Readonly::Scalar our $VERSION => do { my ($r) = q$LastChangedRevision: 5210 $ =~ /(\d+)/mxs; $r; };

has q{col_a}      => (isa => q{Str}, is => q{rw});
has q{col_b}      => (isa => q{Int}, is => q{rw});
has q{col_c}      => (isa => q{Str}, is => q{rw});
has q{col_d}      => (isa => q{Str}, is => q{rw});
has q{col_index}  => (isa => q{Int}, is => q{ro}, writer => q{_set_primary_key});

sub primary_key {
  my ($self) = @_;
  return q{col_index};
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

DB_test

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

A test class for testing MooseX::Storage::DB
Whilst you may use the code here to help develop your own class, this class should not be used for production purposes

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item MooseX::InsideOut

=item MooseX::Storage::DB

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
