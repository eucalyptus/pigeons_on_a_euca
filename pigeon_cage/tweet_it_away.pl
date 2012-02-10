#!/usr/bin/perl

use Net::Twitter::Lite;
use strict;

local $| = 1;



############################## Global Variables ####################################

my $consumer_key= "";
my $consumer_secret = "";
my $access_token = "";
my $access_token_secret = "";

my $bird;

################################### main() #########################################

if( @ARGV < 1 ){
	print print_time(). "\tERROR: No Tweet Input File !!\n";
	print "Usage: ./tweet_a_line.pl <tweet_input_file>\n";
	exit(1);
}; 

my $inputfile = shift @ARGV;

if( !(-e "$inputfile") ){
	print print_time() . "\tERROR: Tweet Input File \'$inputfile\' Does't Exist !!\n";
	exit(1);
};

print "\n";

read_o_auth_settings();

connect_to_bird();

if( check_the_bird() ){
	if( check_the_bird_limit() ){
		my $post = `head -n 1 $inputfile`;
		chomp($post);
		update_to_the_bird($post);
	}else{
		print print_time() . "Error: Connection to Twitter was Restricted !!\n";
	};
}else{
	print print_time() . "Error: Failed to connect to Twitter !!\n";
};

disconnect_bird();
print "\n";

exit(0);


1;


###################################################### SUBROUTINES ############################################################

sub print_time{

	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
	my $this_time = sprintf "[%4d-%02d-%02d %02d:%02d:%02d]", $year+1900,$mon+1,$mday,$hour,$min,$sec;
	return $this_time;
};

sub read_o_auth_settings{

	print print_time() . "\tReading O Auth Settings\n";
	print "\n";

	my $input_file = "./keys/o_auth_settings.keys";
	if( !( -e $input_file) ){
		print print_time() . "\tERROR: Missing O Auth Settings File \'$input_file\' !!\n";
		exit(1);
	};

	open(KEYS, "< $input_file" ) or die $!;
	my $line;
	while($line=<KEYS>){
		chomp($line);
		if( !($line =~ /^#/) ){
			if( $line =~ /^CONSUMER KEY=(\S+)/ ){
				$consumer_key = $1;
			}elsif( $line =~ /^CONSUMER SECRET=(\S+)/ ){
				$consumer_secret = $1;
			}elsif( $line =~ /^ACCESS TOKEN=(\S+)/ ){
				$access_token = $1;
			}elsif( $line =~ /^ACCESS TOKEN SECRET=(\S+)/ ){
				$access_token_secret = $1;
			};
		};
	};
	close(KEYS);

	if( $consumer_key eq "" || $consumer_secret eq "" || $access_token eq "" || $access_token_secret eq "" ){
		print print_time() . "\tERROR: Missing O Auth Settings Keys !!\n";
		print "CONSUMER KEY=" . $consumer_key . "\n";
		print "CONSUMER SECRET=" . $consumer_secret . "\n";
		print "ACCESS TOKEN=" . $access_token . "\n";
		print "ACCESS TOKEN SECRET=" . $access_token_secret . "\n";
		exit(1);
	};

	return 0;
};


sub connect_to_bird{

	print print_time() . "\tConnecting to Twitter\n";
	print "\n";

	$bird = Net::Twitter::Lite->new(
		consumer_key        => $consumer_key,
		consumer_secret     => $consumer_secret,
		access_token        => $access_token,
		access_token_secret => $access_token_secret,
	);

	return 0;
};

sub disconnect_bird{

	print print_time() . "\tDisconnecting from Twitter\n";
	print "\n";

	$bird->end_session();

	return 0;

};

sub check_the_bird{

	if( $bird->authorized ){
		return 1;
	};

	return 0;
};

sub update_to_the_bird{
	my $tweet = shift @_;
	my $is_error = 0;

	print print_time() . "\tUpdating to Twitter\n";
	print "\n\n";
	print "TWEET:\t\"" . $tweet . "\"\n";
	print "\n\n";

	my $result = eval { $bird->update($tweet) };

	if( $@ ){
#		warn "$@\n" if $@;
		print print_time() . "\tWARNING: $@\n";
		print "\n";

		$is_error = 1;
	};

	if( $is_error == 0 ){
		print print_time() . "\tTweeted OK\n";
		print "\n";
	};

	return $is_error;
};


sub check_the_bird_limit{

	my $rate =  $bird->rate_limit_status();

	print print_time(). "\tTwitter Application Rate Limit Status Check\n";
	print "\n";
	print "Reset Time in Seconds:\t" . $rate->{'reset_time_in_seconds'} . "\n";
	print "Hourly Limit:\t" . $rate->{'hourly_limit'} . "\n";
	print "Remaining Hits:\t" . $rate->{'remaining_hits'} . "\n";
	print "Reset Time:\t" . $rate->{'reset_time'} . "\n";
	print "\n";

	if( $rate->{'remaining_hits'} < 10 ){
		print print_time() . "\tWARNING: The Limit has fallen below 10 Hits !!\n";
		return 0;
	};

	return 1;
};

1;
