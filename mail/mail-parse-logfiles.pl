#!/bin/env perl

# Name: mail-parse-logiles.pl
# Date: 7/27/2014
# Purpose: Generate logs about mail messages
#
# Author: me@jpike.net
#
# Global uses
use strict;
#
# Global variables
my $domain = `hostname -d`;

my %hash = ();
my %local_host_names_hash = ();
my %aliases_hash = ();
my $counter = 0;

my $mail_logfile = '/var/log/maillog';

if ( $ARGV[0] ne '' ) {
	$mail_logfile = $ARGV[0];
}

my $local_host_names = '/etc/mail/local-host-names';

my $aliases_file = '/etc/mail/aliases';

my $file_handle;

open $file_handle, "<$aliases_file" or die "Error opening file: $aliases_file! $!\n";

while ( my $aline = <$file_handle> ) {
	chomp $aline;

	if ( $aline =~ m/^\S+:\s(.+)$/ ) {
		my $destination = $1;

		my @parts = split(',', $destination);

		foreach my $address ( @parts ) {
			$aliases_hash{$address} = 'defined';			
		}
	}
}

open $file_handle, "<$local_host_names" or die "Error opening file: $local_host_names! $!\n";

while ( my $aline = <$file_handle> ) {
	chomp $aline;

	next if $aline =~ m/^\s*#/;

	$local_host_names_hash{$aline} = 'defined';
}

close $file_handle;

open $file_handle, "<$mail_logfile" or die "Error opening logfile! $!\n";

while ( my $aline = <$file_handle> ) {
	chomp $aline;

#Oct 19 09:44:26 jinx sm-mta[4418]: l9JDiNUq004418: from=<Ruipetrusa@d111.com>, size=594, class=0, nrcpts=1, msgid=<200710191344.l9JDiNUq004418@jinx.jinxed.net>, proto=ESMTP, daemon=MTA-v4, relay=190-51-98-155.speedy.com.ar [190.51.98.155] (may be forged)
#Oct 19 09:46:30 jinx sm-mta[4420]: l9JDiUUq004420: to=<Ruipetrusa@d111.com>, delay=00:02:00, xdelay=00:02:00, mailer=esmtp, pri=30000, relay=d111.com. [8.15.231.110], dsn=4.0.0, stat=Deferred: Connection timed out with d111.com.
#
## Jul 28 16:26:12 jinx sendmail[12400]: s6SKQAvP012400: from=<bounce-1064-9111908-452-248@twido.biz>, size=0, class=0, nrcpts=0, bodytype=8BITMIME, proto=ESMTP, daemon=MTA-v4, relay=[70.39.91.26]
# Jul 28 16:15:49 jinx sendmail[12211]: s6SKFl0e012211: from=<JesiicaF@ewumbleomsk.com>, size=0, class=0, nrcpts=0, bodytype=8BITMIME, proto=ESMTP, daemon=MTA-v4, relay=66-118-187-208.static.sagonet.net [66.118.187.208]
# Jul 28 16:25:08 jinx sendmail[12384]: s6SKP5aY012375: to=<mom@jpike.net>, delay=00:00:01, xdelay=00:00:00, mailer=local, pri=45443, dsn=2.0.0, stat=Sent
#

	if ( $aline =~ m/^(\S+\s+\S+\s+\S+).*\s(sendmail|sm-mta)\[[0-9]+\]:\s(\S+):\s.*to=(\S+).*stat=(\S+).*$/ ) {
		my $date				= $1;
		my $mail_type 		= $2;
		my $mail_id 		= $3;
		my $to_id			= $4;
		my $stat_id			= $5;

		$to_id =~ s/[<>,]//g;
		$mail_id =~ s/:$//;

		my $to_domain = $to_id;

		if ( $to_domain =~ m/\@/ ) {
			$to_domain =~ s/^.*\@(.+)$/$1/;	
			$to_domain =~ tr/[A-Z]/[a-z]/;
		}
		else {
			$to_domain = $domain;
		}

		$hash{$mail_id}{'topart'}{$counter}{'date'}		= $date;
		$hash{$mail_id}{'topart'}{$counter}{'to'}			= $to_id;
		$hash{$mail_id}{'topart'}{$counter}{'domain'}	= $to_domain;
		$hash{$mail_id}{'topart'}{$counter}{'stat'}		= $stat_id;

		$counter++;
	}
	elsif ( $aline =~ m/^(\S+\s+\S+\s+\S+).*\s(sendmail|sm-mta)\[[0-9]+\]:\s(\S+):\s.*from=(\S+).*relay=(.+)$/ ) {
		my $date			= $1;
		my $mail_type	= $2;
		my $mail_id		= $3;
		my $from_id		= $4;
		my $relay_id	= $5;

		$from_id =~ s/[<>,]//g;
		$mail_id =~ s/:$//;

		my $from_domain = $from_id;
		my $from_user = $from_id;

		if ( $from_domain =~ m/\@/ ) {
			$from_domain =~ s/^.*\@(.+)$/$1/;	
			$from_user =~ s/^(.*)\@(.+)$/$1/;	
			$from_domain =~ tr/[A-Z]/[a-z]/;
		}
		else {
			$from_domain = $domain;
		}

		$hash{$mail_id}{'from'}				= $from_id;
		$hash{$mail_id}{'fromuser'}	   = $from_user;
		$hash{$mail_id}{'fromdomain'}		= $from_domain;
		$hash{$mail_id}{'relay'}			= $relay_id;
		$hash{$mail_id}{'date'}				= $date;
	}
	elsif ( $aline =~ m/^(\S+\s+\S+\s+\S+).*\s(sendmail|sm-mta)\[[0-9]+\]:\s(\S+):\s.*arg1=(\S+)\s.*reject=(.+)$/ ) {
		my $date			= $1;
		my $mail_type	= $2;
		my $mail_id		= $3;
		my $to_id		= $4;
		my $reject 		= $5;

		$to_id =~ s/[<>,]//g;
		$mail_id =~ s/:$//;

		my $to_domain = $to_id;

		if ( $to_domain =~ m/\@/ ) {
			$to_domain =~ s/^.*\@(.+)$/$1/;	
			$to_domain =~ tr/[A-Z]/[a-z]/;
		}
		else {
			$to_domain = $domain;
		}

		# Adjust the reject code
		$reject =~ s/^\d+\s+\d+\.\d+\.\d+\s//g;
		$reject =~ s/\s+\d+\.\d+\.\d+\.\d+(\s+|$)/ /g;
		$reject =~ s/(rejected|for\s)//gi;
		$reject =~ s/\s+$//;
		$reject =~ s/^\s+//;
		$reject =~ s/^\S+\.\.\.\s//;
		$reject =~ s/address\s+\S+\@\S+//;
		$reject =~ s/\s+\S+\.\S+$// if $reject =~ m/mx/i;

		$hash{$mail_id}{'reject'}			= $reject;
		$hash{'reject'}{$reject}++;

		$hash{$mail_id}{'topart'}{$counter}{'date'}		= $date;
		$hash{$mail_id}{'topart'}{$counter}{'to'}			= $to_id;
		$hash{$mail_id}{'topart'}{$counter}{'domain'}	= $to_domain;
		$hash{$mail_id}{'topart'}{$counter}{'stat'}		= 'Rejected - ' . $reject;

		$counter++;
	}
}

close $file_handle;

$hash{'counters'}{'null'}			= 0;
$hash{'counters'}{'domains'}		= 0;
$hash{'counters'}{'aliases'}		= 0;
$hash{'counters'}{'invalid'}		= 0;
$hash{'counters'}{'rejected'}		= 0;

# Jul 28 16:17:08 jinx sendmail[12264]: s6SKH7I6012264: ruleset=check_rcpt, arg1=<jaypike@jinxed.net>, relay=[94.102.51.235], reject=550 5.7.1 <jaypike@jinxed.net>... Fix reverse DNS for 94.102.51.235

foreach my $mail_id ( sort keys %hash ) {

	if ( defined $hash{$mail_id}{'from'} ) {

		foreach my $counter ( sort keys %{$hash{$mail_id}{'topart'}} ) {
			my $found = 0;

			if ( defined $hash{$mail_id}{'topart'}{$counter}{'to'} ) {
				my $to = $hash{$mail_id}{'topart'}{$counter}{'to'};
				my $from = $hash{$mail_id}{'from'};

				if ( defined $hash{$mail_id}{'reject'} ) {
					$hash{'counters'}{'rejected'}++;
					$found++;
				}
				else {
					if ( $hash{$mail_id}{'topart'}{$counter}{'to'} =~ m/null/i ) {
						$hash{'counters'}{'null'}++;
						$found++;
					}

					if ( defined $local_host_names_hash{$hash{$mail_id}{'topart'}{$counter}{'domain'}} ) {
						$hash{'counters'}{'domains'}++;
						$to =~ s/\@.*//;
						$found++;
					}
					elsif ( $local_host_names_hash{$hash{$mail_id}{'fromdomain'}} ) {
						$hash{'counters'}{'domains'}++;
						$from =~ s/\@.*//;
						$found++;
					}

					if ( defined $aliases_hash{$hash{$mail_id}{'topart'}{$counter}{'to'}} ) {
						$hash{'counters'}{'aliases'}++;
						$to = $aliases_hash{$hash{$mail_id}{'topart'}{$counter}{'to'}};
						$found++;
					}
					elsif ( defined $aliases_hash{$hash{$mail_id}{'fromuser'}} ) {
						$hash{'counters'}{'aliases'}++;
						$from = $aliases_hash{$hash{$mail_id}{'fromuser'}};
						$found++;
					}
				}

				if ( $found == 0 
					&& ( $to ne 'root' && $from ne 'root' ) ) {
					$hash{'counters'}{'invalid'}++;
				}

				next if $hash{$mail_id}{'topart'}{$counter}{'to'} =~ m/null/i;
				# next if defined $local_host_names_hash{$hash{$mail_id}{'topart'}{$counter}{'domain'}};
				# next if defined $aliases_hash{$hash{$mail_id}{'topart'}{$counter}{'to'}};

				# print "$hash{$mail_id}{'date'} ";
				print "$hash{$mail_id}{'topart'}{$counter}{'date'} ";
				#print "$hash{$mail_id}{'from'} -> ";
				print "$from -> ";
				#print "$hash{$mail_id}{'topart'}{$counter}{'to'}";
				print "$to";
				print " Status: $hash{$mail_id}{'topart'}{$counter}{'stat'}";
				print " (Unknown local user) " if $found == 0;
				print "\n";
				# print "\tStatus: $hash{$mail_id}{'topart'}{$counter}{'stat'} / Relay: $hash{$mail_id}{'topart'}{$counter}{'relay'}\n";
			}
		}
	}
	else {
		#print "Mail ID: $mail_id does not have matching from and to records!\n";
	}	
}

my %count_hash = ();

foreach my $rejectcode ( sort keys $hash{'reject'} ) {
	$count_hash{$hash{'reject'}{$rejectcode}}{$rejectcode}++;
}

print "\n\nRejects:\n\n";

foreach my $counter ( reverse sort { $a <=> $b } keys %count_hash ) {
	foreach my $rejectcode ( sort { $a <=> $b } keys %{ $count_hash{$counter} } ) {
		print "$rejectcode: $counter\n";
	}
}

print "\nStats:\n\n";
print "Rejected:                  $hash{'counters'}{'rejected'}\n";
print "Known Domain Deliveries:   $hash{'counters'}{'domains'}\n";
print "Known Alias Deliveries:    $hash{'counters'}{'aliases'}\n";
print "Unknown Deliveries:        $hash{'counters'}{'invalid'}\n";
print "Deivered to NULL:          $hash{'counters'}{'null'}\n";
