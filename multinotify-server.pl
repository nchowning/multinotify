#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;

# Flush after every write
$| = 1;

my ($socket,$client_socket);
my ($peeraddress,$peerport);
my @connections = ();

# Socket creation
$socket = new IO::Socket::INET (
    LocalHost => 'IP ADDRESS IN HERE',
    LocalPort => 'PORT IN HERE',
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1
    ) or die "Error in Socket Creation : $!\n";

print "Listening for connections\n\n";

while(1) # To infinity and beyond!
{
    my $client_socket = $socket->accept();
    my $buf = <$client_socket>;
    if ($buf)
    {
        # Variables to hold the client's IP address and port
        $peeraddress = $client_socket->peerhost();
        $peerport = $client_socket->peerport();

        print "Connection to: $peeraddress:$peerport established.\n\n";

        # Check to see what the client is sending.
        if ($buf eq "send\n")
        {
            my $messagepack = &sendmessage;

            # &verifycon returns 1 if a client is present and 0 otherwise
            if (&verifycon == 1)
            {
            &receivemessage($messagepack);
            }
            else
            {
            # Send to prowl
            }
        }
        elsif ($buf eq "receive\n")
        {
# TODO: Need to make sure that this client doesn't already exist in the array
            push (@connections, $client_socket);
            &receiveinit;
        }
    }
}

# TODO: Clean this up.  Send csv packets (username,message,etc...) rather than
# separate packets for each piece of info
sub sendmessage
{
    print "Send request from client $peeraddress:$peerport\n";

    # Send an approval message to the sending client
    my $data = "approved";
    print $client_socket "$data\n";

    # Receive the username and message from the client
    my $received = <$client_socket>;
    print "Received: \"$received\"";

    return $received;
}

# TODO: Initially needs to verify that a client connection exists in the connection hash.
# Needs to verify the connection (will write a new sub for that), and then send a csv packet
# rather than separate packets for each piece of info
sub receivemessage
{
    # Store the message (passed as a parameter)
    my $message = "$_";

# TODO: Call &verifycon before starting this loop

    foreach my $receiver (@connections)
    {
        # Send the message packet to the client
        print $receiver "$message";
    }
}

#TODO: Create &receiveinit
# &receiveinit will verify that the client connection was added to the hash and then verify
# that the client is indeed connected

#TODO: Create &verifycon
# When called, &verifycon will send a "hello_client" packet to all clients that exist in the connection
# hash.  If it does not receive "hello_server" from the client, it will remove that connection from
# the hash.
