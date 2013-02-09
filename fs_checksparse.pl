#!/usr/bin/perl -w

#=================================================================================#
#OS       : - HP-UX                                                               #
#           - Linux                                                               #
#                                                                                 #
#Parameter: Optional                                                              #
#           -h ....................... Help                                       #
#                                                                                 #
#Examples:  fs_checksparse.pl -d /dir                                             #
#           fs_checksparse.pl -d /package/db01/SID_sid -b 16384                   #
#           fs_checksparse.pl -d /dir1 /dir2 -v                                   #
#                                                                                 #
#Author: Pletter Thomas
#=================================================================================#

use strict;
use warnings;
use Config::General; # Show OS: $^O
use File::Basename;
use File::Find;
use Getopt::Long;

#==============================================================================#
#                                                                              #
#          MAIN-PROGRAM                                                        #
#                                                                              #
#==============================================================================#


my $UNIX_OS      = $^O;                             # UNIX_OS
my $ProgName     =  basename ($0); chomp $ProgName;
my $output_one_time           = 0 ;

my %Args          = ();                              
my $BlockSize     = -1;                              # BlockSize for Checks
my @directories   = "" ;                             # Directory for Checks
my $directory     = "" ;
my $Verbose       = 0;                               # Logging STDOUT
my $BlockSize_Opt = 0;

# ----------------------------- #
#       Get Options             #
# ----------------------------- #
my $InOpts = GetOptions( \%Args,
			 'b|blocksize=s'     => \$BlockSize,
			 'd|directory=s{,}'  => \@directories,
			 'v|verbose'         => \$Verbose,
 			 'h|help'            => sub { &show_Usage; }
		       );

# ------------------------------------- #
#       Check Options                   #
# ------------------------------------- #

&show_Usage if( ! $InOpts);                      # errors at cmdline-parameters

&show_Usage if( $#directories == 0 );            # errors at cmdline-parameters

$BlockSize_Opt = 1 if( $BlockSize != -1 );  # Set Value , if a defined BlockSize

print "UNIX-VERSION: $UNIX_OS\n" if( $Verbose);

CASE: {
  # HP-UX
  $UNIX_OS  eq "hpux" && do { last CASE;
                            };
  # Linux
  $UNIX_OS  eq "linux" && do { last CASE;
                            };
  # Default 
                              print STDERR "$ProgName: not supported UNIX-VERSION $UNIX_OS\n" ;
                              exit 1;
}


# Remove Array Elements with ''
my $index = 0;
$index++ until $directories[$index] eq '';
splice(@directories, $index, 1);

foreach $directory (@directories) 
{
  if ( ! -d $directory )
  {
    print STDERR "$ProgName: Directory $directory does not exist !!\n";
    exit 1;
  }
  print "Check von Directory: $directory\n" if( $Verbose);
}

#==============================================================================#
#                                                                              #
#          PROCEDURE                                                           #
#                                                                              #
#==============================================================================#

sub process_file {
  my $f=$File::Find::name;
  if(-f)
  {

    (my $dev,my $ino,my $mode,my $nlink,my $uid,my $gid,my $rdev,my $size,my $atime,my $mtime,my $ctime,my $blksize,my $blocks) = stat($f);

    # Define Outputs , if Verbose
    print "BlockSize (Defined) : $BlockSize\n" if( $Verbose && $BlockSize_Opt == 1 && $output_one_time  == 0);
    print "BlockSize (Detected): $blksize\n" if( $Verbose && $BlockSize_Opt == 0 && $output_one_time  == 0);
    print "Attention: Check with another BlockSize: $BlockSize (Filesystem-BlockSize: $blksize)\n" if( $BlockSize_Opt == 1 && $output_one_time  == 0);

    # Set another $blksize Example: ORACLE RDBMS Files
    $blksize = $BlockSize if( $BlockSize_Opt == 1 );
    printf ("            blksize: %5d, blocks: %15.0f size: %15.0f file: %s\n",$blksize,$blocks,$size,$f) if( $Verbose);

    my $blocks_used=$blocks*$blksize/8;
    # my $blocks_used=$blocks*$blksize/8;
    # my $blocks_used=$blocks*512;   # bei Angabe von Default Werte z.B.: Linux
    printf ("sparsefile: blksize: %5d, size:   %15.0f actual space used: %15.0f file: %s\n",$blksize,$size,$blocks_used,$f) if ($blocks_used < $size);

    # Output of $BlockSize should only one time printed
    $output_one_time           = 1 ;
  }
}

sub show_Usage {
  print <<"__end_usage__";

  USAGE: $ProgName [options]
  Check SparseFiles
  Options:
  -d|--directories (1-n) One or more Directories
  -v|--verbose           verbose output
  -h|--help              Help

  EXAMPLES:
  Help
  $ProgName -h

  Check SparseFiles Directory '/dir'
  $ProgName -d /dir

  Check SparseFiles of ORACLE-Filesystem(Directory) '/package/db01/SID_sid' with BlockSize 16384
  $ProgName -d /package/db01/SID_sid -b 16384

  Check SparseFiles of Directories '/dir1', '/dir2' with Output
  $ProgName -d /dir1 /dir2 -v

__end_usage__

  exit (1);
};

find(\&process_file,@directories);
