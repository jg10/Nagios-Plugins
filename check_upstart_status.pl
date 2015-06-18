#! /usr/bin/perl -w
#
#  check_upstart_status.pl
#  by Jeremy Goldstein
#
#  This nagios check checks the status of upstart jobs
#
# Copyright (c) 2012 Jeremy Goldstein
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
# 0 = ok
# 1 = warn
# 2 = crit
# 3 = unknown

#configurable options:
my $debug = 0;

# No changes below, unless you want to change exit codes
use lib "/usr/lib/nagios/plugins";
use Getopt::Std;
use strict;
use warnings;
use utils qw( %ERRORS);

%ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3);
my $exit_value = $ERRORS{'UNKNOWN'} ;

my %options=();

getopts("j:", \%options);

if (scalar(keys(%options))<1 )
{
	show_usage();
}

my $jobName = $options{'j'};
my $exit_value_human="";
my $retval;
my $goal;
my $state;

#Run command and get result
my $cmd = "service $jobName status";
$retval = `$cmd`;

#Get return code
my $retnum = $?>>8;

#Check return code to see if job was found
if ($retnum > 0)
{
	$exit_value = $ERRORS{'UNKNOWN'};
	$retval = 'Error - Job name may not have been found';
}
else
{
	#Remove trailing \n and replace with trailing comma as quick hack
	$retval =~ s/\n/,/;

	if ($retval =~ m/$jobName (.*)\/.*/)
	{
		$goal = $1;
	}

	if ($retval =~ m/.*\/(.*),/)
	{
		$state = $1;
	}

	if ($debug)
	{
		print "Command run: $cmd\n";
		print "Result: $retval\n";
	} 

	if ($goal eq "stop")
	{
		$exit_value = $ERRORS{'CRITICAL'};
	}
	elsif ($state eq "pre-stop")
	{
		$exit_value = $ERRORS{'WARNING'};
	}
	elsif ($state eq "stopping")
	{
		$exit_value = $ERRORS{'WARNING'};
	}
	elsif ($state eq "killed")
	{
		$exit_value = $ERRORS{'WARNING'};
	}
	elsif ($state eq "post-stop")
	{
		$exit_value = $ERRORS{'WARNING'};
	}
	else
	{
		$exit_value = $ERRORS{'OK'};
	}
}

if ($exit_value == 0)
{
	$exit_value_human = "OK";    
}
elsif ($exit_value == 1)
{
	$exit_value_human = "WARNING";    
}
elsif ($exit_value == 2)
{
	$exit_value_human = "CRITICAL";    
}
elsif ($exit_value == 3)
{
	$exit_value_human = "UNKNOWN";    
}

#Remove trailing comma hack
$retval =~ s/,$//;

print $retval . ". STATUS: $exit_value_human\n";
exit $exit_value;
		
sub show_usage
{
	print "\n\n";
	print "check_upstart_status.pl\n";
	print "by Jeremy Goldstein\n";
	print "\n";
	print "This nagios check checks the status of upstart jobs\n";
	print "and alerts when the job is not running.\n";
	print "\n";
	print "usage:\n";
	print "./check_upstart_status.pl -j jobName\n";
	print "\n";
	print "-j jobName\t\t The name of the upstart job you want to check\n";
	print "\n\n";

	exit $exit_value;
}
