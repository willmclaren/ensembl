## Bioperl Test Harness Script for Modules
##
# CVS Version
# $Id$


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

#-----------------------------------------------------------------------
## perl test harness expects the following output syntax only!
## 1..3
## ok 1  [not ok 1 (if test fails)]
## 2..3
## ok 2  [not ok 2 (if test fails)]
## 3..3
## ok 3  [not ok 3 (if test fails)]
##
## etc. etc. etc. (continue on for each tested function in the .t file)
#-----------------------------------------------------------------------


## We start with some black magic to print on failure.
BEGIN { $| = 1; print "1..13\n"; 
	use vars qw($loaded); }
END {print "not ok 1\n" unless $loaded;}

use Bio::EnsEMBL::DBSQL::Obj;
use Bio::EnsEMBL::DBLoader;
$loaded=1;
print "ok \n";    # 1st test passed, loaded needed modules

#Creating test overlap database

$conf{'overlap'}      = 'testoverlap';
$conf{'mysqladmin'} = '/mysql/current/bin/mysqladmin';
$conf{'mysql'}      = '/mysql/current/bin/mysql';
$conf{'user'}       = 'root';
$conf{'perl'}       = 'perl';

if ( -e 't/overlap.conf' ) {
  print STDERR "Reading configuration from overlap.conf\n";
  open(C,"t/overlap.conf");
  while(<C>) {
    my ($key,$value) = split;
    $conf{$key} = $value;
  }
} else {
  print STDERR "Using default values\n";
  foreach $key ( keys %conf ) {
    print STDERR " $key $conf{$key}\n";
  }
  print STDERR "\nPlease use a file t/overlap.conf to alter these values if the test fails\nFile is written <key> <value> syntax\n\n";
}

$nuser = $conf{user};

my $create_overlap        = "$conf{mysqladmin} -u ".$nuser." create $conf{overlap}";

system($create_overlap)   == 0 or die "$0\nError running '$create_overlap' : $!";

print "ok 2\n";    #Databases created successfuly

#Initialising databases
my $init_overlap        = "$conf{mysql} -u ".$nuser." $conf{overlap} < ../sql/table.sql";

system($init_overlap)     == 0 or die "$0\nError running '$init_overlap' : $!";

print "ok 3\n";

#Suck test data into db
print STDERR "Inserting test data in test overlap db...\n";
my $suck_data      = "$conf{mysql} -u ".$nuser." $conf{overlap} < t/overlap.dump";
system($suck_data) == 0 or die "$0\nError running '$suck_data' : $!";

print "ok 4\n";

# Connect to test db

my $db             = new Bio::EnsEMBL::DBSQL::Obj(-host   => 'localhost',
						  -user   => $conf{user},
						  -dbname => $conf{overlap}
						 );

die "$0\nError connecting to database : $!" unless defined($db);

print "ok 5\n";

my $contig = $db->get_Contig('contig1');

die "$0\nError fetching contig1 : $!" unless defined ($contig);

print "ok 6\n";

my $vc     = new Bio::EnsEMBL::DB::VirtualContig(-focuscontig   => $contig,
						 -focusposition => 1,
						 -ori           => 1,
						 -left          => 20,
						 -right         => 20);

die ("$0\nCan't create virtual contig :$!") unless defined ($vc);

print "ok 7\n";

my $seq      = $vc->primary_seq;
print STDERR "Sequence is [" .$seq->seq ."] Should be AAAACCCCTTGGGAAA\n";

die "$0\nVirtual contig sequence " . $seq->seq . "does not equal AAAACCCCTTGGGAAA : $!" if ($seq->seq ne "AAAACCCCTTGGGAAA");
  
print "ok 8\n";


if( $vc->length != $vc->primary_seq->length ) {
   print "not ok 9\n";
} else {
   print "ok 9\n";
}

$vc =  new Bio::EnsEMBL::DB::VirtualContig(-focuscontig   => $contig,
						 -focusposition => 1,
						 -ori           => 1,
						 -left          => 2,
						 -right         => 2);

if( $vc->length != $vc->primary_seq->length ) {
   print "not ok 10\n";
} else {
   print "ok 10\n";
}


my $vc     = new Bio::EnsEMBL::DB::VirtualContig(-focuscontig   => $contig,
						 -focusposition => 1,
						 -ori           => 1,
						 -left          => 20,
						 -right         => 20);


@sf = $vc->get_all_SimilarityFeatures();
if( $#sf == -1 ) {
     print "not ok 11\n";
} else {
  print "ok 11\n";
}

@sf = $vc->get_all_PredictionFeatures();
if( $#sf == -1 ) {
     print "not ok 12\n";
} else {
  print "ok 12\n";
}


@sf = $contig->get_all_PredictionFeatures();
if( $#sf == -1 ) {
     print "not ok 13\n";
} else {
  print "ok 13\n";
}

my $contig = $db->get_Contig('contig6');
my $contig2 = $db->get_Contig('contig7');



my $vc     = new Bio::EnsEMBL::DB::VirtualContig(-focuscontig   => $contig,
						 -focusposition => 4,
						 -ori           => 1,
						 -left          => 30,
						 -right         => 30);

$vc->_dump_map(\*STDOUT);

@sf = $vc->get_all_SimilarityFeatures();
$sf = shift @sf;
@sf = $sf->sub_SeqFeature();
$sf = shift @sf;

print "On vc, sequence is ",$sf->seq->seq,"\n";

@sf = $contig2->get_all_SimilarityFeatures();
$sf = shift @sf;
@sf = $sf->sub_SeqFeature();
$sf = shift @sf;
print "On contig, sequence is ",$sf->seq->seq,"\n";

END {
    my $drop_overlap        = "echo \"y\" | $conf{mysqladmin} -u ".$nuser." drop $conf{overlap}";
   system($drop_overlap)     == 0 or die "$0\nError running '$drop_overlap' : $!";
}




