#!/usr/bin/perl

$dirname = @ARGV[0];

opendir ( DIRINPUT, "$dirname" ) || die "Error opening directory $dirname!\n";

while ( $aline = readdir DIRINPUT )
	{
	if ( $aline =~ m/\.OK$/ )
		{
		$newname = $aline;
		$newname =~ s/\.OK$//;

		print "Renameing: $aline to: $newname\n";
		rename ( $aline, $newname );
		}
	if ( $aline =~ m/\.[0-9]+$/ )
		{
		$newname = $aline;
		$newname =~ s/\.[0-9]+$//;

		print "Renameing: $aline to: $newname\n";
		rename ( $aline, $newname );
		}
	}
		
