#!/usr/bin/perl

use strict;

local $| = 1;

my $TWEET_CLIENT_DIR = "/root/blog";			### Directory Location of "tweet_it_away.pl"

my $CREDENTIALS = "./credentials/eucarc";	### Default Credentials Location
my $CLOUD_CLIENT_TOOL = "euca";			### Default Cloud Client Tool
my $CLOUD_CLIENT_TOOL_VERSION = "1.0.0";	### Default Cloud CLient Tool Version

my $SLEEP = 60;					### 60 sec Sleep per Check
my $RESET_PERIOD = 10;				### $SLEEP x $RESET_PERIOD = PERIODIC CHECK ON EUCALYPTUS

############################## main() ####################################

if( -e "./conf/pigeons_on_a_euca.conf" ){
	read_config();
};


if( !(-e $CREDENTIALS) ){
	print print_time() . "\tERROR: Missing Credentials \'$CREDENTIALS\' !!\n";
	exit(1);
};

if( !(-e $TWEET_CLIENT_DIR) ){
	print print_time() . "\tERROR: Missing Twitter Client Directory \'$TWEET_CLIENT_DIR\' !!\n";
	exit(1);
};

###	Find out Cloud Client Tool Version
check_cloud_client_tool_version();

###	Cleanup ./tmp Directory
system("rm -f ./tmp/*");

print "\n";
print "PIGEONS ARE ACTIVATED at " . print_time() . "\n";
print "\n";

my $timer = 0;

while(1){

	frequent_check_on_euca();

	if( $timer == 0 ){
		periodic_check_on_euca();
	};
	
	if( $timer > $RESET_PERIOD ){
		$timer = 0;
	}else{
		$timer++;
	};

	print print_time() . "\tSleeping for 60 sec\n";
	print "\n";
	print "...\n";
	print "\n";
	sleep(60);
};

print "\n";
print "HUH?\n";
print "\n";

exit(0);


1;



###################################################### SUBROUTINES ############################################################

sub print_time{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
	my $this_time = sprintf "[%4d-%02d-%02d %02d:%02d:%02d]", $year+1900,$mon+1,$mday,$hour,$min,$sec;
	return $this_time;
};

sub print_bird_time{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
	my $this_time = sprintf "[%02d-%02d %02d:%02d]", $mon+1,$mday,$hour,$min;
	return $this_time;
};


sub read_config{

	print "\n";
	print print_time() . "\tReading ./conf/pigeons_on_a_euca.conf";
	print "\n";

	my $temp = `cat ./conf/pigeons_on_a_euca.conf`;
	my @conf_array = split("\n", $temp);
	foreach my $line (@conf_array){
		if( !($line =~ /^#/) ){
			if( $line =~ /^(\S+)\s+(.+)/ ){
				print "$line\n";
				my $key = $1;
				my $value = $2;
				if( $key eq "TWEET_CLIENT_DIR" ){
					$TWEET_CLIENT_DIR = $value;
				}elsif( $key eq "CREDENTIALS" ){
					$CREDENTIALS = $value;
				}elsif( $key eq "CLOUD_CLIENT_TOOL" ){
					$CLOUD_CLIENT_TOOL = $value;
				}elsif( $key eq "SLEEP" ){
					$SLEEP = $value;
				}elsif( $key eq "RESET_PERIOD" ){
					$RESET_PERIOD = $value
				};	
			};
		};
	};
	print "\n";

	return 0;
};

sub frequent_check_on_euca{

	print "\n";	
	print print_time() . "\tChecking Eucalyptus\n";
	print "\n";
	print "\n";

	check_on_running_instances();
	print "\n";

	print "\n";
	return 0;
};


sub periodic_check_on_euca{

	print "\n";
	print print_time() . "\tPerforming Periodic Check on Eucalyptus\n";
	print "\n";
	print "\n";

	check_on_running_instances_count();
	print "\n";

	check_on_unique_instances_count();
	print "\n";

	check_on_availability_zones();
	print "\n";

	print "\n";
	return 0;
};

sub  cloud_system{

	my $line = shift @_;

	if( $CLOUD_CLIENT_TOOL eq "ec2" ){
		$line =~ s/^euca-/ec2-/;
	};

	my $cmd = "bash -c \"source $CREDENTIALS; " . $line . "\"";
	
	print print_time() . "\t$cmd\n";
	my $output = `$cmd`;

	return $output;
};

sub check_cloud_client_tool_version{
	my $output = cloud_system("euca-version");
	if( $output =~ /^euca2ools\s+([\d\.]+)/ ){
		$CLOUD_CLIENT_TOOL_VERSION = $1;
	};
	print "CLOUD_CLIENT_TOOL_VERSION\t$CLOUD_CLIENT_TOOL_VERSION\n";

	return 0;
};

sub tweet_it_out{

	my $line = shift @_;
	my $tweet = print_bird_time() . " $line";

	print "\n";
	print "\n";
	print "============================= TWEETING ====================================\n";
	print "\n";

	print "Tweet:\t$tweet\n";

	my $filename = "temp.tweet";
	my $outfile = "$TWEET_CLIENT_DIR/tweets/$filename";
	system("echo \"$tweet\" > $outfile"); 

	my $length = `wc -m $outfile`;
	chomp($length);
	if( $length =~ /^(\d+)\s/ ){
		$length = $1;
	};

	print "LENGTH:\t$length\n";
	print "\n";

	if( $length > 140 ){
		print print_time() . "\tWARNING: Tweet is longer than 140 characters\n";
		print "\n";
	};


	print print_time() . "\tcd $TWEET_CLIENT_DIR; perl ./tweet_it_away.pl ./tweets/$filename\n";
	system("cd $TWEET_CLIENT_DIR; perl ./tweet_it_away.pl ./tweets/$filename");
	print "\n";

	print "============================= TWEETED =====================================\n";
	print "\n";
	print "\n";

	return 0;
};

################################################# CUSTOM CHECKS #########################################################

sub check_on_running_instances{

	print print_time() . "\tChecking on Running Instances\n";
	print "\n";

	my %instance_hash;

	###	Get the recent instance description
	my $command = "euca-describe-instances";
	if( $CLOUD_CLIENT_TOOL_VERSION =~ /^2\./ ){
		$command .= " verbose";
	};
	my $output = cloud_system($command);

	if( $output eq "" ){
		print "No Instances Running\n";
	}else{
		print $output;
		print "\n";
	};

	my @new_array = split("\n", $output);
	my %new_hash;
	foreach my $line (@new_array){
		if( $line =~ /^INSTANCE\s+(\S+)\s+(\S+)\s+([\d\.]+)\s+([\d\.]+)\s+(\w+)\s+/ ){
#			print "$1 $5\n";
			$new_hash{$1} = $5;
			$instance_hash{$1} = 1;
		};
	};

	###	Get the previous instance description
	my $old_record_file = "./tmp/old_instance_record.list";
	my $old_record = `cat $old_record_file`;

	my @old_array = split("\n", $old_record);
	my %old_hash;
	foreach my $line (@old_array){
		if( $line =~ /^INSTANCE\s+(\S+)\s+(\S+)\s+([\d\.]+)\s+([\d\.]+)\s+(\w+)\s+/ ){
#			print "$1 $5\n";
			$old_hash{$1} = $5;
			$instance_hash{$1} = 1;
		};
	};

	###	Compare
	my $str = "";
	foreach my $key (keys %instance_hash){
		my $old_state = $old_hash{$key};
		my $new_state = $new_hash{$key};
		$str .= $key . " ";			### create instance ID string

		if( $old_state eq "" ){
			$old_state = "NULL";
		};

		if( $new_state eq "" ){
			$new_state = "NULL";
		};

#		print "$key\t$old_state\t$new_state\n";

		if( $old_state ne $new_state ){
			my $report = "Instance $key Updated: [ $old_state => $new_state ]\n";
			tweet_it_out($report);
		};
	}; 

	system("echo \"$output\" > $old_record_file");

	record_unique_instance_ids($str);

	return 0;
};


sub record_unique_instance_ids{

	my $str = shift @_;
	my $id_file = "./tmp/unique_instance_ids.list";

	if ( !(-e $id_file) ){
		system("echo \"$str\" > $id_file");
		return 0;
	};
	
	my $temp = `cat $id_file`;
	my @old_id_array = split(" ", $temp);
	my %id_hash;
	foreach my $line (@old_id_array){
		$id_hash{$line} = 1;
	};

	my @new_id_array = split(" ", $str);
	foreach my $line (@new_id_array){
		$id_hash{$line} = 1;
	};

	my $new_str = "";
	foreach my $id (keys %id_hash){
		$new_str .= $id . " ";
	};

	system("echo \"$new_str\" > $id_file");
	return 0;

	return 0;
};

sub check_on_unique_instances_count{

	print print_time() . "\tChecking on Running Instances Count\n";
	print "\n";
	
	my $id_file = "./tmp/unique_instance_ids.list";
	my $temp = `cat $id_file`;
	my @id_array = split(" ", $temp);
	my $count = @id_array;
	
	my $report = "Unique Instances Since Last Check: $count\n";
	tweet_it_out($report);

	system("rm -f $id_file");

	return 0;
};


sub check_on_running_instances_count{

	print print_time() . "\tChecking on Running Instances Count\n";
	print "\n";

	###	Get the recent instance description
	my $command = "euca-describe-instances";
	if( $CLOUD_CLIENT_TOOL_VERSION =~ /^2\./ ){
		$command .= " verbose";
	};
	my $output = cloud_system($command);

	my $count = 0;

	if( $output eq "" ){
		print "No Instances Running\n";
	}else{
		print $output;
	};
	print "\n";

	my @new_array = split("\n", $output);
	my %new_hash;
	foreach my $line (@new_array){
		if( $line =~ /^INSTANCE\s+(\S+)\s+(\S+)\s+([\d\.]+)\s+([\d\.]+)\s+(\w+)\s+/ ){
			my $state = $5;
			if(  $5 eq "running" ){
				$count++;
			};
		};
	};

	my $report = "Running Instances Count: $count\n";
	tweet_it_out($report);

	return 0;
};

sub check_on_availability_zones{

	print print_time() . "\tChecking Availability Zones\n";
	print "\n";

	my $output = cloud_system("euca-describe-availability-zones verbose");
	print $output;
	print "\n";

	my @lines = split("\n", $output);
	my $report = "";
	foreach my $line (@lines){
#		print "Line: " . $line . "\n";

		if( $line =~ /^AVAILABILITYZONE\s+(.+)/ ){
			my $content = $1;
			if( $content =~ /^(\S+)\s+([\d\.]+)\s+(\S+)/ ){
				my $this_parti = $1;

				if( $report ne ""){
#					print "TWEET: " . $report . "\n";
					tweet_it_out($report);
				};

				$report = "";
				$report = "<PT: $this_parti>";
			}elsif( $content =~ /^\|\-\s+(\S+)\s+(\d+)\s+\/\s+(\d+)\s+/){
				my $type = $1;
				my $avail = int($2);
				my $max = int($3);
				$report .= " $type $avail/$max";
			};
		};		
	};

	if( $report eq "" ){
		$report = "ERROR: No Availability Zones Information\n";
	};

#	print "TWEET: " . $report . "\n";
	tweet_it_out($report);

	return 0;
};


1;

