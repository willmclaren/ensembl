use strict;
use warnings;

package Bio::EnsEMBL::DBSQL::MetaCoordContainer;

use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::DBSQL::BaseAdaptor;
use Bio::EnsEMBL::Utils::Exception;

@ISA = qw(Bio::EnsEMBL::DBSQL::BaseAdaptor);




sub new {
  my $class = shift;

  my $self = $class->SUPER::new(@_);

  #
  # Retrieve the list of the coordinate systems that features are stored in
  # and cache them
  #
  my $sth = $self->prepare
    ('SELECT table_name, coord_system_id, max_length  FROM meta_coord');
  $sth->execute();

  while(my ($table_name, $cs_id, $max_length) = $sth->fetchrow_array()) {
    $self->{'_feature_cache'}->{lc($table_name)} ||= [];
    push @{$self->{'_feature_cache'}->{lc($table_name)}}, $cs_id;
    $self->{'_max_len_cache'}->{$cs_id}->{lc($table_name)} = $max_length;
  }
  $sth->finish();

  return $self;
}




=head2 fetch_all_CoordSystems_by_feature_type

  Arg [1]    : string $table - the name of the table to retrieve coord systems
               for.  E.g. 'gene', 'exon', 'dna_align_feature'
  Example    : @css = @{$mcc->fetch_all_CoordSystems_by_feature_type('gene')};
  Description: This retrieves the list of coordinate systems that features
               in a particular table are stored.  It is used internally by
               the API to perform queries to these tables and to ensure that
               features are only stored in appropriate coordinate systems.
  Returntype : listref of Bio::EnsEMBL::CoordSystem objects
  Exceptions : throw if name argument not provided
  Caller     : BaseFeatureAdaptor

=cut

sub fetch_all_CoordSystems_by_feature_type {
  my $self = shift;
  my $table = lc(shift); #case insensitive matching

  throw('Name argument is required') unless $table;

  if(!$self->{'_feature_cache'}->{$table}) {
    return [];
  }

  my @cs_ids = @{$self->{'_feature_cache'}->{$table}};
  my @coord_systems;

  my $csa = $self->db->get_CoordSystemAdaptor();

  foreach my $cs_id (@cs_ids) {
    my $cs = $csa->fetch_by_dbID($cs_id);

    if(!$cs) {
      throw("meta_coord table refers to non-existant coord_system $cs_id");
    }

    push @coord_systems, $cs;
  }

  return \@coord_systems;
}



=head2 fetch_max_length_by_CoordSystem_feature_type

  Arg [1]    : Bio::EnsEMBL::CoordSystem $cs
  Arg [2]    : string $table
  Example    : $max_len = 
                $mcc->fetch_max_length_by_CoordSystem_feature_type($cs,'gene');
  Description: Returns the maximum length of features of a given type in
               a given coordinate system.
  Returntype : int or undef
  Exceptions : throw on incorrect argument
  Caller     : BaseFeatureAdaptor

=cut


sub fetch_max_length_by_CoordSystem_feature_type {
  my $self = shift;
  my $cs = shift;
  my $table = shift;

  if(!ref($cs) || !$cs->isa('Bio::EnsEMBL::CoordSystem')) {
    throw('Bio::EnsEMBL::CoordSystem argument expected');
  }

  throw("Table name argument is required") unless $table;

  return $self->{'_max_len_cache'}->{$cs->dbID()}->{lc($table)};
}



=head2 add_feature_type

  Arg [1]    : Bio::EnsEMBL::CoordSystem $cs
               The coordinate system to associate with a feature table
  Arg [2]    : string $table - the name of the table in which features of
               a given coordinate system will be stored in
  Example    : $csa->add_feature_table($chr_coord_system, 'gene');
  Description: This function tells the coordinate system adaptor that
               features from a specified table will be stored in a certain
               coordinate system.  If this information is not already stored
               in the database it will be added.
  Returntype : none
  Exceptions : none
  Caller     : BaseFeatureAdaptor

=cut


sub add_feature_type {
  my $self = shift;
  my $cs   = shift;
  my $table = lc(shift);

  if(!ref($cs) || !$cs->isa('Bio::EnsEMBL::CoordSystem')) {
    throw('CoordSystem argument is required.');
  }

  if(!$table) {
    throw('Table argument is required.');
  }

  my $cs_ids = $self->{'_feature_cache'}->{$table} || [];

  my ($exists) = grep {$cs->dbID() == $_} @$cs_ids;

  #do not do anything if this feature table is already associated with the
  #coord system
  return if($exists);

  #store the new tablename -> coord system relationship in the db
  #ignore failures b/c during the pipeline multiple processes may try
  #to update this table and only the first will be successful
  my $sth = $self->prepare('INSERT IGNORE INTO meta_coord ' .
                              'SET coord_system_id = ?, ' .
                                  'table_name = ?');

  $sth->execute($cs->dbID, $table);

  #update the internal cache
  $self->{'_feature_cache'}->{$table} ||= [];
  push @{$self->{'_feature_cache'}->{$table}}, $cs->dbID();

  return;
}


1;
