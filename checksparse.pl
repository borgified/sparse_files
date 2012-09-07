#!/usr/bin/perl -w
use strict;
use warnings;

if(!defined(@ARGV)){
        print "$0 <full path>\n";
        exit;
}

use File::Find;
use File::Stat qw/:stat/;

sub process_file {
         my $f=$File::Find::name;
        if(-f){
                my ($dev,$ino,$mode,$nlink, $uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($f);
                my $blocks_used=$blocks*$blksize;
                if ($blocks_used < $size) {
                        print "$f => size: $size actual space used: $blocks_used\n";
                }
        }
}
find(\&process_file,@ARGV);

