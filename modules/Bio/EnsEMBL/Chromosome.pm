# BioPerl module for Bio::EnsEMBL::Chromosome
#
# Creator: Arne Stabenau <stabenau@ebi.ac.uk>
# Date of creation: 07.04.2000
# Last modified : 09.04.2000 by Arne Stabenau
#
# Copyright EMBL-EBI 2000
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::EnsEMBL::Chromosome

=head1 SYNOPSIS


=head1 DESCRIPTION

Contains very basic information of a chromosome and access methods
for global features of a chromosome. It does not have the sequence or
more detailed information - check out StaticGoldenPathAdaptor for that
(you will want to make a virtual contig of the chromosome)

    
=head1 CONTACT


    Contact Arne Stabenau on implemetation/design detail: stabenau@ebi.ac.uk
    Contact Ewan Birney on EnsEMBL in general: birney@sanger.ac.uk


=head1 APPENDIX

The rest of the documentation details each of the object methods. Internal methods are usually preceded with a _
    
=cut


# Let the code begin...


package Bio::EnsEMBL::Chromosome;
use vars qw(@ISA);
use strict;
use Bio::Root::RootI;
use Bio::EnsEMBL::Species;



@ISA = qw( Bio::Root::RootI );


sub new {
    my ($class,@args) = @_;
    
    my $self = {};
    bless $self,$class;


    my ($chrname,$adaptor) = $self->_rearrange([qw(CHRNAME ADAPTOR)],@args);

    if( !defined $chrname || !defined $adaptor ) {
	$self->throw("Badly formed chromosome");
    }
    $self->adaptor($adaptor);
    $self->chrname($chrname);

    return $self;
}


=head2 get_landmark_MarkerFeatures

 Title   : get_landmark_MarkerFeatures
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub get_landmark_MarkerFeatures{
   my ($self,@args) = @_;

   return $self->adaptor->get_landmark_MarkerFeatures($self->chrname);
}



=head2 chrname

 Title   : chrname
 Usage   : $obj->chrname($newval)
 Function: 
 Example : 
 Returns : value of chrname
 Args    : newvalue (optional)


=cut

sub chrname{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'chrname'} = $value;
    }
    return $obj->{'chrname'};

}

=head2 adaptor

 Title   : adaptor
 Usage   : $obj->adaptor($newval)
 Function: 
 Example : 
 Returns : value of adaptor
 Args    : newvalue (optional)


=cut

sub adaptor{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'adaptor'} = $value;
    }
    return $obj->{'adaptor'};

}


# compiled successfull

1;




