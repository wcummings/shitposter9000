my %config = (host => "",
	      user => "",
	      pass => "",
	      nick => "",
	      realname => "",
	      giphy_api_key => "",
	      channels => ['#shitposting', '#general'],
              twitter => {
		  consumer_secret => '',
		  consumer_key => '',
		  access_token => '',
		  access_token_secret => ''
              });

sub get_config { \%config }

