use constant APP_NAME => 'multinotify';
use IO::Socket::INET;

if (eval{ require Gtk2::Notify; }){
  $notifier = 'libnotify';
} elsif (eval{ require Mac::Growl; }){
  my @notify_on = ('alert');
  Mac::Growl::RegisterNotifications(APP_NAME, \@notify_on, \@notify_on);
  $notifier = 'growl';
} else {
  print <<HERE;
    No notifier module installed. 
    Please install one of the supported notification modules.
HERE
  die;
}

$| = 1;

my ($socket,$client_socket);

$socket = new IO::Socket::INET (
    PeerHost => 'IP_ADDRESS',
    PeerPort => 'PORT_NUMBER',
    Proto => 'tcp',
    ) or die "ERROR in Socket Creation : $!\n";

print "Connection Successful.\n";

$data = "receive";
print $socket "$data\n";

sub notify {
  my($username, $message) = @_;
  if ($notifier eq 'libnotify'){
    # libnotify is picky and doesn't like '<' or '>' so these two regex lines remove them
    $message =~ s/<//gi;
    $message =~ s/>//gi;
    
    my $notification = Gtk2::Notify->new($username, $message);
    $notification->show;
  } elsif ($notifier eq 'growl'){
    Mac::Growl::PostNotification(APP_NAME, 'alert', $username, $message);
  }
}

while(<$socket>)
{
    # Store the username in $username and chomp it to remove the newline
    chomp($username = $_);

    # Be courteous and tell the server "thanks"
    $data = "thanks";
    print $socket "$data\n";

    # Store the message in $message and chomp it to remove the newline
    chomp($message = <$socket>);

    # Send the username and message to notify
    notify($username, $message);
}
$socket->close();
