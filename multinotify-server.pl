#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket::INET;

# Flush after every write
$| = 1;

my ($socket,$client_socket);
my ($peeraddress,$peerport);
our %connections = ();

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
            $connections { $client_socket } = 0;
            &verifycon;
        }
    }
}

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

sub receivemessage
{
    # Store the message (passed as a parameter)
    my $message = "$_";

    if (&verifycon == 1)
    {
        foreach my $receiver (keys %connections)
        {
            # Adds 1 to the csv packet to signify that the packet is a message
            my $data = "1,$message";

            # Send the message packet to the client
            print $receiver "$data\n";
        }
    }
    else
    {
        print "No receiving clients exist.  Something went wrong.\n\n";
    }
}

sub verifycon
{
    foreach my $receiver (keys %connections)
    {
        my $data = "hello_client";
        print $receiver "$data\n";

        my $reply = <$receiver>;
        chomp($reply);
        if ($reply ne "hello_server")
        {
            delete $connections{$receiver};
        }
    }

    if (!keys %connections)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}
