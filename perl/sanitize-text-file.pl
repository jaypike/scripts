#!/usr/bin/perl
#
# Name: sanitize-text-file.pl
# Date: 10/27/2006
# Purpose: To clean up the input of a specified file to only have
#				listed text in it.
# Author: jaypike@jinxed.Com
#
#

# Global uses
use strict;

# Global variables
my $filename;

# Check for filename in usage
foreach my $inputcommand (@ARGV) {
	if ( $inputcommand =~ m/^\-/ ) {
		if ( $inputcommand eq '-i' ) {
		} elsif ( $inputcommand eq '-v' ) {
		}
	} else {
		$filename = $inputcommand;
	}
}

if ( $filename eq '' ) {
	print "Syntax Error: $0 <options> <filename>\n";
#	print "\tOptions:\n";
#	print "\t\t-i: Only print Invalid/Expired licsenses\n";
#	print "\t\t-v: Only print Valid licsenses\n";
	exit;
}

# Try and open and parse the file
open ( FILEHANDLE, "$filename" ) || die "Error opening $filename!!\n";


while ( my $aline = <FILEHANDLE> ) {
	chomp ( $aline );

	$aline =~ s/\033.7m//g;
	$aline =~ s/\033.m//g;
	$aline =~ s/\033\[[0-9]\;[0-9]m//g;
	$aline =~ s/\033\[[0-9]+[A-Z]//g;
	$aline =~ s/\033\[[A-Z]//g;
	$aline =~ s/\033\[\@.//g;
	$aline =~ s/\033//g;
	$aline =~ s/\015//g;
	$aline =~ s/\s\010//g;
	$aline =~ s/\010//g;
	$aline =~ s/\007//g;
	$aline =~ s/^\]0;//g;

	print "$aline\n";
}

close ( FILEHANDLE );
