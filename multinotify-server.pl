use warnings;
use IO::Socket::INET;
use IO::Select;

# Flush after every write
$| = 1;

my ($socket,$client_socket);
my ($peeraddress,$peerport);

# Socket creation
$socket = new IO::Socket::INET (
    LocalHost => 'IP_ADDRESS',
    LocalPort => 'PORT_NUMBER',
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1
    ) or die "Error in Socket Creation : $!\n";

# Create a handle set
my ($read_set) = new IO::Select();
# Add the main socket to the set
$read_set->add($socket);

print "Listening for connections\n\n";

while(1) # To infinity and beyond!
{
    # Get a set of (somewhat) usable handles
    my ($rh_set) = IO::Select->select($read_set, undef, undef, 0);

    # Use each handle
    foreach $rh (@$rh_set)
    {
        # Accept the incoming connection and add it to the $read_set
        if ($rh == $socket)
        {
            $client_socket = $rh->accept();
            $read_set->add($client_socket);
        }
        # Ordinary socket.  Read it and process.
        else
        {
            $buf = <$rh>;
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

                    # If $receiver has a defined value, a receiving client
                    # is connected in which case we need to call &receivemessage
                    # to send the new message onto the receiving client.
                    if(defined($receiver))
                    {
                        &receivemessage;
                    }
                    else
                    {
                        # Send to Prowl... eventually
                    }
                }
                else
                {
                    # If the client did not send "send" to the socket, it is a
                    # receiving client.  Set the $receiver variable and call the
                    # &receivemessage subroutine.
                    $receiver = $rh;
                    &receivemessage;
                }
            }
            # The client has closed the socket.
            else
            {
                # If $receiver is set, the receiving client is connected to the server.
                if(defined($receiver))
                {
                    # Check to see if the disconnecting client is the receiving client.
                    # If it is, undefine the $receiver variable.
                    if($rh eq $receiver)
                    {
                        undef $receiver
                    }
                }
                # Remove the client from $read_set and close it.
                print "Client disconnected.\n\n";
                $read_set->remove($rh);
                close($rh);
            }
        }
    }
}

sub sendmessage
{
    print "Send request from client $peeraddress:$peerport\n";

    # Send an approval message to the sending client
    $data = "approved";
    print $client_socket "$data\n";

    # Receive the username from the client and store it in $username
    $username = <$client_socket>;
    print "Username: $username";

    # Send the value "un" to the client to verify that the username was received
    $data = "un\n";
    print $client_socket "$data\n";

    # Receive the message from the client and store it in $message
    $message = <$client_socket>;
    print "Message: $message\n";
}

sub receivemessage
{
    # If the variable $username is defined, a message has been sent
    if (defined($username))
    {
        # Send the username to the client
        print $receiver "$username";

        # If the server received "thanks" form the receiving client proceed to
        # send the message to the client
        if (<$receiver> eq "thanks\n")
        {
            print $receiver "$message";
        }
        # Undefine the $username variable
        undef($username);
    }
}
