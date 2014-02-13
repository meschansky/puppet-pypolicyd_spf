class { 'pypolicyd_spf' :
  	debuglevel 	       => 3,
	defaultseedonly    => 0,
	helo_reject	       => 'Softfail',
	mail_from_reject   => 'No_Check',
	permerror_reject   => true,
	temperror_defer    => true,
	skip_addresses     => '192.168.0.0/24',
}