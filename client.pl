use warnings;
use IO::Socket::SSL;

my $IPADDRESS = "127.0.0.1";
my $PORT = "5730";

$| = 1; # Flush after write
my ($socket,$client_socket);

######
# Send messages to notification server
######
sub socketsend {
    my(@smessage) = @_;
    $socket = new IO::Socket::SSL->new(
        PeerHost => "$IPADDRESS",
        PeerPort => "$PORT",
        SSL_verify_mode => SSL_VERIFY_NONE
        ) or die "ERROR in Socket Creation : $!\n";

    # Send "send" to the server to inform it that this is a sending client
    $data = "SEND";
    print $socket "$data" . "\r\n";

    # Send the message to the server
    $data = "$smessage[0],,$smessage[1]";
    print $socket "$data" . "\r\n";

    # Close the socket
    close($socket);
}

socketsend("This is a test","HELLO!?");
