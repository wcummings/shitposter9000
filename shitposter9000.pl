#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent ();
use JSON ();
use URI::Encode ();
use Net::Twitter ();
use Text::SlackEmoji ();
require "./config.pl";
my $config = get_config();

package Shitposter9000;
use base qw(Bot::BasicBot);

my $giphy_search_endpoint = "http://api.giphy.com/v1/gifs/search?api_key=%s&q=%s";
my $cats_dir = "https://wpc.io/cats/";
my $pigs_dir = "https://wpc.io/pigs/";

my $twitter = Net::Twitter->new(
    traits   => [qw/API::RESTv1_1/],
    consumer_key        => $config->{twitter}->{consumer_key},
    consumer_secret     => $config->{twitter}->{consumer_secret},
    access_token        => $config->{twitter}->{access_token},
    access_token_secret => $config->{twitter}->{access_token_secret}
);

my $emoji = Text::SlackEmoji->emoji_map;

my $ua = LWP::UserAgent->new;

sub said {
    my ($self, $arguments) = @_;

    if ($arguments->{body} =~ /^!([^\s]+)\s*(.*)/) {
	my ($command, $params) = ($1, $2);
	if (my $code = Shitposter9000->can('cmd_' . $command)) {
	    print "Executing command: $command\n";
	    $self->$code($arguments, $params);
	}
    }
}

# sub chanjoin {
#     my ($self, $arguments) = @_;
#     $self->say(channel => $arguments->{channel},
#     	       body    => $greeting);
# }

sub cmd_pig {
    my ($self, $arguments) = @_;
    if (rand() > 0.5) {
	$self->cmd_gif($arguments, "pig");
    } else {
	$pig = choose_file_from_index($pigs_dir, "mp4");
	if ($pig) {
	    $self->say(channel => $arguments->{channel},
		       body    => $pig);
	} else {
	    $self->say(channel => $arguments->{channel},
		       body    => "Error getting pigs.");
	}
    }
}

sub cmd_sexy {
    my ($self, $arguments) = @_;
}

sub choose_file_from_index {
    my ($url, $suffix) = @_;
    my $response = $ua->get($url);
    if ($response->is_success) {
	my @files;
	my $content = $response->decoded_content;
	while ($content =~ /\"(.*?\.$suffix)\"/g) {
	    push @files, $1;
	}
	$url . choice(\@files);
    }
}

sub cmd_cat {
    my ($self, $arguments) = @_;
    my $gif = choose_file_from_index($cats_dir, "gif");
    if ($gif) {
	$self->say(channel => $arguments->{channel},
		   body    => $gif);
    } else {
	$self->say(channel => $arguments->{channel},
		   body    => "Error getting cats.");
    }
}

sub cmd_gif {
    my ($self, $arguments, $q) = @_;

    my $gif = giphy_search(URI::Encode::uri_encode($q));
    if ($gif) {
	my $url = $gif->{images}->{fixed_height}->{url};
	print "Saying: $url\n";
	$self->say(channel => $arguments->{channel},
		   body    => $url);
    } else {
	$self->say(channel => $arguments->{channel},
		   body    => "Error from giphy API.");
    }
}

sub cmd_shitpost {
    my ($self, $arguments, $tweet) = @_;

    $tweet =~ s!:([-+a-z0-9_]+):!$emoji->{$1} // ":$1:"!ge;
    
    eval {
	my $result = $twitter->update($tweet);
	$self->say(channel => $arguments->{channel},
		   body    => "Done");
    };
    if (my $err = $@) {
	my $error_msg = $err->error;
	$error_msg =~ s/at shitposter9000.pl.*//g;
	$self->say(channel => $arguments->{channel},
		   body    => "Error with twitter API: " . $error_msg);
    }
}

sub giphy_search {
    my ($q) = @_;
	
    my $url = sprintf $giphy_search_endpoint, $config->{giphy_api_key}, $q;
    my $response = $ua->get($url);
    if ($response->is_success) {
	my $response_body = JSON::decode_json $response->decoded_content;
	choice($response_body->{data});
    }
}

sub choice {
    my ($a_ref) = @_;
    my @a = @{$a_ref};
    $a[rand @a];
}

package main;

my $bot = Shitposter9000->new(server   => $config->{host},
			      port     => '6697',
			      channels => $config->{channels},
			      nick     => $config->{nick},
			      name     => $config->{realname},
			      password => $config->{pass},
			      username => $config->{user},
			      ssl      => 1);
$bot->run();
