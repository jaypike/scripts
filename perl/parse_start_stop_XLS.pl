#!/usr/bin/perl
#
# Name: parse_start_stop_XLS.pl
# Date: 12/22/2006
# Purpose: To parse a simple input file format based on generic
#				start and stop headers and provide output that will
#				easily import into a Excel spreadsheet.
# Author: jaypike@jinxed.Com
#
#

# Global uses - This requires the Date::Calc package.
use strict;

# Global Variables
my $startdelimiter = "startofoutput";
my $startdelimiter1 = ".* echo EndOfCommand";
my $enddelimiter = "endofoutput";
my $enddelimiter2 = "EndOfCommand";
my $fieldseparator = "\t";
my $inloop = 0;
my $outputline;

# Check for filename in usage
my $filename = @ARGV[0];

if ( $filename eq '' ) {
	print "Syntax Error: $0 <filename>\n";
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
    $aline =~ s/\010//g;
    $aline =~ s/\007//g;
    $aline =~ s/^\]0;//g;

	$aline =~ tr/A-Za-z0-9#\/ \t.:&$*_@-//cd;
    #$aline =~ s/\s/ /g;
    $aline =~ s/\s+$//g;

	# Flip the inloop variable when we find the delimiters
	if ( $aline =~ m/^($startdelimiter|$startdelimiter1)$/i ) {
		$outputline = "";
		$inloop = 1;
	} elsif ( $aline =~ m/^($enddelimiter|$enddelimiter2)$/i 
        && $inloop == 1 ) {
		$inloop = 0;
		chop ( $outputline );
		print "$outputline\n";
	} elsif ( $inloop == 1 ) { # Print the lines in between the field seperators
		$outputline .= $aline . $fieldseparator;
	}
}
