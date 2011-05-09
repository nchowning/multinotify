use IO::Socket::INET;
use Gtk2::Notify;

$| = 1;

my ($socket,$client_socket);

#my $notification = Gtk2::Notify->new($summary, $message, $icon, $attach_widget);
#    $notification->show;

$socket = new IO::Socket::INET (
    PeerHost => 'IP_ADDRESS',
    PeerPort => 'PORT',
    Proto => 'tcp',
    ) or die "ERROR in Socket Creation : $!\n";

print "Connection Successful.\n";

$data = "receive";
print $socket "$data\n";

while(<$socket>)
{
    # Store the username in $username and chomp it to remove the newline
    chomp($username = $_);

    # Be courteous and tell the server "thanks"
    $data = "thanks";
    print $socket "$data\n";

    # Store the message in $message and chomp it to remove the newline
    chomp($message = <$socket>);

    # libnotify is picky and doesn't like '<' or '>' so these two regex lines remove them
    $message =~ s/<//gi;
    $message =~ s/>//gi;

    # Send the username and message to libnotify
    my $notification = Gtk2::Notify->new($username, $message);
    $notification->show;
}
$socket->close();
