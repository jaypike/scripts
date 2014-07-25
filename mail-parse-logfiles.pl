#!/usr/bin/perl
#
#

use strict;

my $domain = "jinxed.net";

my %hash = ();
my %local_host_names_hash = ();
my %aliases_hash = ();
my $counter = 0;

my $mail_logfile = '/var/log/mail.log';

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

	if ( $aline =~ m/^(\S+\s+\S+\s+\S+).*\ssm-mta\[[0-9]+\]:\s(\S+)\s.*to=(\S+).*stat=(.+)$/ ) {
		my $date		= $1;
		my $mail_id = $2;
		my $to_id	= $3;
		my $stat_id	= $4;

		$to_id =~ s/,//g;
		$mail_id =~ s/:$//;

		my $to_domain = $to_id;

		if ( $to_domain =~ m/\@/ ) {
			$to_domain =~ s/[<>]//g;
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
	elsif ( $aline =~ m/^(\S+\s+\S+\s+\S+).*\ssm-mta\[[0-9]+\]:\s(\S+)\s.*from=(\S+).*relay=(.+)$/ ) {
		my $date			= $1;
		my $mail_id		= $2;
		my $from_id		= $3;
		my $relay_id	= $4;

		$from_id =~ s/,//g;
		$mail_id =~ s/:$//;

		$hash{$mail_id}{'from'}		= $from_id;
		$hash{$mail_id}{'relay'}	= $relay_id;
		$hash{$mail_id}{'date'}		= $date;
	}
}

close $file_handle;

$hash{'counters'}{'null'}		= 0;
$hash{'counters'}{'domains'}	= 0;
$hash{'counters'}{'aliases'}	= 0;
$hash{'counters'}{'valid'}		= 0;

foreach my $mail_id ( sort keys %hash ) {

	if ( defined $hash{$mail_id}{'from'} ) {

		foreach my $counter ( sort keys %{$hash{$mail_id}{'topart'}} ) {

			if ( defined $hash{$mail_id}{'topart'}{$counter}{'to'} ) {

				if ( $hash{$mail_id}{'topart'}{$counter}{'to'} =~ m/null/i ) {
					$hash{'counters'}{'null'}++;
				}
				elsif ( defined $local_host_names_hash{$hash{$mail_id}{'topart'}{$counter}{'domain'}} ) {
					$hash{'counters'}{'domains'}++;
				}
				elsif ( defined $aliases_hash{$hash{$mail_id}{'topart'}{$counter}{'to'}} ) {
					$hash{'counters'}{'aliases'}++;
				}

				next if $hash{$mail_id}{'topart'}{$counter}{'to'} =~ m/null/i;
				next if defined $local_host_names_hash{$hash{$mail_id}{'topart'}{$counter}{'domain'}};
				next if defined $aliases_hash{$hash{$mail_id}{'topart'}{$counter}{'to'}};

				#print "$hash{$mail_id}{'date'} ";
				print "$hash{$mail_id}{'topart'}{$counter}{'date'} ";
				print "$hash{$mail_id}{'from'} -> ";
				print "$hash{$mail_id}{'topart'}{$counter}{'to'} Status: $hash{$mail_id}{'topart'}{$counter}{'stat'}\n";
				#print "\tStatus: $hash{$mail_id}{'topart'}{$counter}{'stat'} / Relay: $hash{$mail_id}{'topart'}{$counter}{'relay'}\n";

				$hash{'counters'}{'valid'}++;
			}
		}
	}
	else {
		#print "Mail ID: $mail_id does not have matching from and to records!\n";
	}	
}

print "\nStats: \n";
print "Unknown Deliveries:        $hash{'counters'}{'valid'}\n";
print "Known Domain Deliveries:   $hash{'counters'}{'domains'}\n";
print "Known Alias Deliveries:    $hash{'counters'}{'aliases'}\n";
print "Deivered to NULL:          $hash{'counters'}{'null'}\n";
