#!/bin/sh -- # -*- perl -*-
# Note: The above is to permit this script to be executed as a begin.sh style
#       script which uses /bin/sh to invoke the script.  Also note, 'perl'
#       requires the word 'perl' in the first line of the script.
eval 'exec perl -X -S $0 ${1+"$@"} ;'
    if 0;

package PikeSpellingTutor;
# $Id: pike.spelling.tutor.pl 1007 2011-08-11 13:56:12Z jaypike $

#  Author: James Pike <jaypike@jinxed.net>
#    Date: November 17, 2011
#  Script: pike.spelling.tutor.pl
# Purpose: Script to help work on spelling capabilities
#

# Global Uses
use 5.004000;    # Require Perl >= 5.4.0
use strict;      # Require implicit variable definitions

#use warnings;                   # Provide warning outputs
use Carp;                       # This gives us croak
use Getopt::Long;               # Load the getopts() function
use FindBin qw($RealBin);       # Finds the current directory of this script
use Sys::Hostname;              # Function call to get the local hostname
use Symbol qw( gensym );        # For creating file handles
use Socket;                     # FOr IP address resolution routines
use File::Copy;                 # For 'copy' command for files
use Time::localtime;            # For localtime object
use Socket;                     # To be used for IP address resolution
use Net::Domain qw(hostfqdn);   # Use to get fully qualified domain name

$| = 1; # Set autoflush for stdout

$ENV{PATH} = "/usr/bin/:/sbin/:/usr/sbin/";    # Setup a secure path environment

# Adjust 'RealBin' path
#$RealBin =~ s/\/\w+[\/]?$/\//;
#$RealBin =~ s/bin[\/]?$//;

# Global Variables
my $pid             = $$;
my $programname     = $0;
$programname        =~ s/^.*\/([^\/]+)$/$1/;
my $hostname        = hostname;
my $tm_obj          = localtime;
my $datetime        = sprintf( "%04d%02d%02d-%02d%02d", $tm_obj->year+1900, $tm_obj->mon+1, $tm_obj->mday, $tm_obj->hour, $tm_obj->min );
my $commandline     = $0 . " @ARGV";
my $DEBUG           = 0;
my $rootdir         = '/';
my $logfile         = "$rootdir/var/tmp/$programname.$hostname.$datetime.log";
my $mode            = '';
my $arch            = `uname -m`; chop $arch;
my $timeout         = 5;
my $tmpdir          = "/tmp/$pid.tmpdir";
my $script_version  = '$Id: pike.spelling.tutor.pl 1007 2011-08-11 13:56:12Z jaypike $';


# Trap interrupts
my $int             = 0;
$SIG{INT} = sub {
    $int++;
    syswrite (STDERR, "Interrupt Detected!\n", 20);
    exit if $int == 5;
};

# Main Build Hash
my %main_hash      = ();

# Main program loop
my $self = PikeSpellingTutor->new();

# Print Log Stanza
$self->log("=============================================================");
$self->log("Program Name: $programname");
$self->log("PID: $pid");
$self->log("Date/Time: $datetime");
$self->log("Command Line: $commandline");
$self->log("Logfile: $logfile");
$self->log("Hostname: $hostname");
$self->log("Arch: $arch");
$self->log("Script Version: $script_version");
$self->log("=============================================================");
$self->log("");

$self->get_data();
$self->quiz();
$self->print_scores();

# ---------------------------------------------------------
# <<<<<< Main Program Functions ONLY below this line >>>>>>
# ---------------------------------------------------------

# new routine for creating new references
sub new () {
	my $class = shift;
	my $self  = {
		'DEBUG'					=> \$DEBUG,
		'logfile'				=> \$logfile,
		'hostname'				=> \$hostname,
		'datetime'				=> \$datetime,
		'commandline'			=> \$commandline,
		'rootdir'				=> \$rootdir,
		'arch'					=> \$arch,
		'tmpdir'					=> \$tmpdir,
		'timeout'				=> \$timeout,
		'mainhash'				=> \%main_hash,
	};
	bless $self, $class;
	return $self;
}

# Log Routine
sub log ($) {
	my $self = shift;
	my $message = shift;

	my $filehandle = gensym();

	my $local_tm_obj          = localtime;
	my $local_datetime        = sprintf( "%04d%02d%02d-%02d%02d%02d", $local_tm_obj->year+1900, $local_tm_obj->mon+1, $local_tm_obj->mday, $local_tm_obj->hour, $local_tm_obj->min, $local_tm_obj->sec );

	open $filehandle, ">>${$self->{'logfile'}}" or die "Error writing to logfile: ${$self->{'logfile'}}! $!\n";

	printf $filehandle "%s: %s\n", $local_datetime, $message;

	close $filehandle;
}

# Get words
sub get_data () {
	my $self = shift;
	my $counter = 0;
	my $exit_loop = 0;

	while ( $exit_loop == 0 ) {
		$self->print_words();

		printf STDOUT "\n%s\n\n", '#'x80;
		printf STDOUT "Option (enter new word, hit return/<enter> to start quiz, or type 'q' to exit): ";

		my $input = <>;
		chomp $input;

		$input =~ tr/A-Z/a-z/;

		$self->exitprogram() if $input =~ m/^(q|quit|exit)$/i;

		if ( $input eq '' ) {
			$exit_loop++;
		}
		else {
			$self->{'mainhash'}->{'words'}->{$counter}->{'word'} = $input;
			$self->log("Word number $counter: $input");
			$counter++;
		}
	}
}

# Print the input words
sub print_words () {
	my $self = shift;
	
	system("clear");

	printf STDOUT "\n%s\n\n", '#'x80;
	printf STDOUT "Pike Family Word Tutor\n";
	printf STDOUT "\n%s\n\n", '#'x80;

	foreach my $element ( sort { $a <=> $b } keys %{ $self->{'mainhash'}->{'words'} } ) {
		printf STDOUT "%s) %s\n", $element, $self->{'mainhash'}->{'words'}->{$element}->{'word'};
	}

	printf STDOUT "\n%s\n\n", '#'x80;

}

# Print the scores
sub print_scores () {
	foreach my $element ( sort { $a <=> $b } keys %{ $self->{'mainhash'}->{'words'} } ) {
		printf STDOUT "%s) %s (tries: %s)\n", $element, $self->{'mainhash'}->{'words'}->{$element}->{'word'}, $self->{'mainhash'}->{'words'}->{$element}->{'tries'};
		$self->log("$element) word: $self->{'mainhash'}->{'words'}->{$element}->{'word'} (tries: $self->{'mainhash'}->{'words'}->{$element}->{'tries'})");
	}
}

# Exit routine
sub exitprogram () {
    my $self = shift;

    $self->log("User requested to exit program!");
    exit 1;
}

# Start the quiz
sub quiz () {
	my $self = shift;

	system("clear");

	printf STDOUT "\n%s\n\n", '#'x80;
	printf STDOUT "Start of test\n";
	printf STDOUT "\n%s\n\n", '#'x80;

	sleep 2;

	foreach my $element ( sort { $a <=> $b } keys %{ $self->{'mainhash'}->{'words'} } ) {
		my $try_counter = 0;
		my $exit_loop = 0;

		while ( $exit_loop == 0 ) {
			system("clear");

			printf STDOUT "%s) ", $element;

			my $input = <>;
			chomp $input;

			$self->exitprogram() if $input =~ m/^(q|quit|exit)$/i;

			$input =~ tr/A-Z/a-z/;
			$input =~ s/ //g;

			if ( "$input" eq "$self->{'mainhash'}->{'words'}->{$element}->{'word'}" ) {
				system("clear");

				$self->log("Correct for word: $self->{'mainhash'}->{'words'}->{$element}->{'word'} - Text entered was $input for try $try_counter");

				printf STDOUT "\n%s\n\n", '#'x80;
				printf STDOUT "Correct!\n";
				printf STDOUT "\n%s\n\n", '#'x80;

				sleep 1;

				$self->{'mainhash'}->{'words'}->{$element}->{'tries'} = $try_counter;
				$exit_loop++;
			}
			else {
				system("clear");

				$self->log("Misspell for word: $self->{'mainhash'}->{'words'}->{$element}->{'word'} - Text entered was $input for try $try_counter");

				printf STDOUT "\n%s\n\n", '#'x80;
				printf STDOUT "Word %s spelled incorrectly, try again!\n", $element;
				printf STDOUT "\n%s\n\n", '#'x80;

				sleep 1;

				$try_counter++;
			}
		}
	}
}
