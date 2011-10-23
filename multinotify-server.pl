#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;

# Flush after every write
$| = 1;

my ($socket,$client_socket);
my ($peeraddress,$peerport);
# TODO: Create hash to hold open connections

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
    $client_socket = $socket->accept();
    $buf = <$client_socket>;
    if ($buf)
    {
        # Variables to hold the client's IP address and port
        $peeraddress = $client_socket->peerhost();
        $peerport = $client_socket->peerport();

        print "Connection to: $peeraddress:$peerport established.\n\n";

        # Check to see what the client is sending.
        # If it's sending "send", call the &sendmessage subroutine.
        # Otherwise call the &recievemessage subroutine.
        if ($buf eq "send\n")
        {
            &sendmessage;

# TODO: Need to verify that a listening client is connected.  If not, forward to prowl
            &receivemessage;
        }
        elsif ($buf eq "receive\n")
        {
# TODO: Add $client_socket to the connection hash
            $receiver = $client_socket;
# TODO: Call new subroutine &receiveinit
            new Thread \&receivemessage;
        }
    }
}

# TODO: Clean this up.  Send csv packets (username,message,etc...) rather than
# separate packets for each piece of info
sub sendmessage
{
    print "Send request from client $peeraddress:$peerport\n";

    # Send an approval message to the sending client
    $data = "approved";
    print $client_socket "$data\n";

    # Receive the username from the client and store it in $username
    $username = <$client_socket>;
    print "Username: $username";
    push (@message_list, $username);

    # Send the value "un" to the client to verify that the username was received
    $data = "un\n";
    print $client_socket "$data\n";

    # Receive the message from the client and store it in $message
    $message = <$client_socket>;
    print "Message: $message\n";
    push (@message_list, $message);
}

# TODO: Initially needs to verify that a client connection exists in the connection hash.
# Needs to verify the connection (will write a new sub for that), and then send a csv packet
# rather than separate packets for each piece of info
sub receivemessage
{
    # If the variable $username is defined, a message has been sent
    if ($message_check == 1)
    {
        # Send the username to the client
        print $receiver "$message_list[0]";
        # If the server received "thanks" form the receiving client proceed to
        # send the message to the client
        if (<$receiver> eq "thanks\n")
        {
            print $receiver "$message_list[1]";
        }
        @message_list = ();
        # Undefine the $username variable
        $message_check = 0;
    }
}

#TODO: Create &receiveinit
# &receiveinit will verify that the client connection was added to the hash and then verify
# that the client is indeed connected

#TODO: Create &verifycon
# When called, &verifycon will send a "hello_client" packet to all clients that exist in the connection
# hash.  If it does not receive "hello_server" from the client, it will remove that connection from
# the hash.
